#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10,<3.13"
# dependencies = ["torch", "diffusers", "pillow", "numpy"]
#
# # ponytail: cu126 is the last build with Pascal (sm_61) kernels for the 1080 Ti.
# # Drop this whole block on a newer GPU and let torch pick its default wheel.
# [tool.uv.sources]
# torch = { index = "pytorch-cu126" }
# [[tool.uv.index]]
# name = "pytorch-cu126"
# url = "https://download.pytorch.org/whl/cu126"
# explicit = true
# ///
"""Adversarial cloak against Stable Diffusion img2img (PhotoGuard-style encoder attack).

Pushes the image's VAE latent toward flat grey, so img2img/inpainting reconstructs
mush instead of your artwork. Does nothing against a human with a paintbrush.

    ./cloak.py design.png                    # -> design_cloaked.png
    ./cloak.py design.png --eps 10 --steps 300
"""
import argparse
import pathlib

import numpy as np
import torch
from PIL import Image
from diffusers import AutoencoderKL

VAE = "stabilityai/sd-vae-ft-mse"


def attack(x: torch.Tensor, vae, eps: float, steps: int, lr: float) -> torch.Tensor:
    """PGD on one tile: drag its VAE latent toward the latent of flat grey."""
    target = vae.encode(torch.zeros_like(x)).latent_dist.mean.detach()
    delta = torch.zeros_like(x).uniform_(-eps, eps).requires_grad_(True)
    opt = torch.optim.Adam([delta], lr=lr)

    for _ in range(steps):
        loss = torch.nn.functional.mse_loss(
            vae.encode((x + delta).clamp(-1, 1)).latent_dist.mean, target
        )
        opt.zero_grad()
        loss.backward()
        opt.step()
        with torch.no_grad():
            delta.clamp_(-eps, eps)
            delta.data = (x + delta).clamp(-1, 1) - x
    return (x + delta).clamp(-1, 1).detach(), loss.item()


def cloak(img: Image.Image, eps: float, steps: int, lr: float, tile: int, device: str):
    vae = AutoencoderKL.from_pretrained(VAE).to(device).eval().requires_grad_(False)

    # ponytail: pad to a multiple of the tile size, then crop back, so the
    # output is pixel-identical in dimensions to the input.
    w, h = img.size
    padded = Image.new("RGB", (w + (-w) % tile, h + (-h) % tile))
    padded.paste(img, (0, 0))

    x = torch.from_numpy(np.array(padded)).float().div(127.5).sub(1)
    x = x.permute(2, 0, 1).unsqueeze(0).to(device)

    # ponytail: non-overlapping tiles. The perturbation is noise-like, so tile
    # seams are invisible; switch to overlap-blend only if they ever show up.
    tiles = [(r, c) for r in range(0, x.shape[2], tile) for c in range(0, x.shape[3], tile)]
    for n, (r, c) in enumerate(tiles, 1):
        patch, loss = attack(x[:, :, r:r + tile, c:c + tile], vae, eps, steps, lr)
        x[:, :, r:r + tile, c:c + tile] = patch
        print(f"  tile {n}/{len(tiles)}  latent mse {loss:.4f}", flush=True)

    out = x.add(1).mul(127.5).round().byte().squeeze(0).permute(1, 2, 0).cpu().numpy()
    return Image.fromarray(out).crop((0, 0, w, h))


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("image", type=pathlib.Path)
    p.add_argument("-o", "--out", type=pathlib.Path)
    p.add_argument("--eps", type=float, default=6, help="max pixel change, 0-255 scale")
    p.add_argument("--steps", type=int, default=200)
    p.add_argument("--lr", type=float, default=0.01)
    p.add_argument("--tile", type=int, default=512, help="tile size; lower if VRAM is tight")
    a = p.parse_args()

    device = "cuda" if torch.cuda.is_available() else "cpu"
    out = a.out or a.image.with_name(f"{a.image.stem}_cloaked.png")
    print(f"cloaking {a.image} on {device} (eps={a.eps}/255, {a.steps} steps)")

    img = Image.open(a.image).convert("RGB")
    cloak(img, a.eps / 127.5, a.steps, a.lr, a.tile, device).save(out)  # PNG only: JPEG erases it
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
