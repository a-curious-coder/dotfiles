# llama.cpp on M4 Pro 24 GB: Qwen3.6-27B tuning

Researched 2026-08-08 against llama.cpp build `10310` (`cb26014d9`) on this MacBook Pro (`Mac16,7`, 14-core M4 Pro, 24 GB unified memory).

## Conclusion

There is no official Qwen3.6-27B/M4 optimization script to install. Use llama.cpp's built-in automatic parameter fitting and `llama-bench`; add a custom script only if repeated measurements become tedious.

`Qwen3.6-27B-Q4_K_M.gguf` is 16.8 GB before KV cache and runtime buffers. That alone is 70% of this machine's unified memory—the upper bound llama.cpp's Apple Silicon guidance recommends for the whole workload. It can run, but it is the quality-at-the-edge preset, not the fast or multitasking preset. Qwen3.5 9B remains the sensible daily model; use 27B when quality is worth closing memory-heavy apps. [Unsloth model file](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF/blob/main/Qwen3.6-27B-Q4_K_M.gguf), [llama.cpp Apple Silicon guidance](https://github.com/ggml-org/llama.cpp/discussions/15396#discussioncomment-14080741)

## Recommended runtime policy

Keep only the limits that express how this machine will be used:

```ini
ctx-size = 32768
cache-type-k = q8_0
cache-type-v = q8_0
parallel = 1
```

Leave these unset so current llama.cpp chooses them:

- `n-gpu-layers`: server default `auto`; automatic fitting is on and targets 1024 MiB of device headroom.
- `flash-attn`: default `auto`; Metal supports Flash Attention and quantized KV caches.
- `threads`, `threads-batch`, `batch-size`, `ubatch-size`: current automatic/default values are the baseline to beat.
- `load-mode`: default `mmap`; do not pin this 16.8 GB model with `mlock` on a 24 GB machine.
- RoPE/YaRN settings: Qwen3.6 is natively 262,144 tokens, but native support does not mean that context is memory-safe here. Keep the deliberate 32K ceiling.

The authoritative defaults and environment-variable equivalents are in the [llama-server CLI reference](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md#common-params). Metal and Apple's Accelerate framework are enabled by default in normal macOS builds; the Homebrew binary on this machine already reports both Metal and BLAS backends. [Official build guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#metal-build), [feature matrix](https://github.com/ggml-org/llama.cpp/wiki/Feature-matrix)

Why keep Q8 KV: it cuts KV-cache storage substantially versus the F16 default while retaining more precision than Q4 KV. Keep K and V the same type; quantized V cache requires Flash Attention on supported paths. This is principally a memory/headroom choice, not a guaranteed speed boost.

## Existing tools

- `llama-fit-params` previews what automatic fitting would select. It is a memory fitter, not a performance tuner. Explicit GPU-layer/tensor overrides remove those choices from automatic fitting. [Official fitting announcement](https://github.com/ggml-org/llama.cpp/discussions/18049)
- `llama-bench` measures prompt processing and token generation separately, repeats each case, accepts comma-separated parameter sweeps, and reports mean tokens/second plus deviation. It excludes tokenization and sampling time. [Official benchmark README](https://github.com/ggml-org/llama.cpp/blob/master/tools/llama-bench/README.md)
- `scripts/compare-llama-bench.py` compares saved benchmark results across builds. It is useful for upgrade regressions, unnecessary for the first local sweep. [Official comparison script](https://github.com/ggml-org/llama.cpp/blob/master/scripts/compare-llama-bench.py)

## Smallest safe measurement

Finish downloads and close memory-heavy apps first. Do not benchmark while another model is loading. Record the installed commit:

```sh
llama-bench --version
```

Capture the current production-shaped baseline (five repetitions are the tool default, stated explicitly for reproducibility):

```sh
llama-bench \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  -p 512 -n 128 -r 5 \
  -ctk q8_0 -ctv q8_0 \
  -fa auto -b 2048 -ub 512 \
  -o json > /tmp/qwen36-baseline.json
```

Then test only the two plausible knobs, four combinations total:

```sh
llama-bench \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  -p 512 -n 128 -r 5 \
  -ctk q8_0 -ctv q8_0 \
  -fa auto,off -b 2048 -ub 256,512
```

Choose a candidate only when its gain exceeds the reported run-to-run deviation. Prefer generation (`tg128`) for interactive chat and prompt processing (`pp512`) for long document ingestion. If `auto` wins or ties, keep it and add no setting.

Do not begin by sweeping threads, GPU layers, cache formats, context, batch and microbatch together: the cross-product obscures which change helped and puts unnecessary memory pressure on this machine.

## What the linked article changes

The article's useful lesson is model sizing, not a hidden M4 switch: it found a 9B Q4 model responsive with enough headroom and found larger models that technically fit but were impractical. Its temperature/top-p/top-k values control output behaviour, not Metal inference throughput, so they should be treated as a separate model-quality preset. [Referenced article](https://jola.dev/posts/running-local-models-on-m4)

## Sources

- [Qwen3.6-27B official model card](https://huggingface.co/Qwen/Qwen3.6-27B)
- [Unsloth Qwen3.6-27B GGUF model card](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF)
- [llama.cpp server CLI reference](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)
- [llama.cpp benchmark reference](https://github.com/ggml-org/llama.cpp/blob/master/tools/llama-bench/README.md)
- [llama.cpp macOS build guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#metal-build)
