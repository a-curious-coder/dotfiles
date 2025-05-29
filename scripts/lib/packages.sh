#!/usr/bin/env bash

# Package Management Library
# ==========================
# Functions for managing packages using the unified packages.yaml configuration

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/platform.sh"
source "$SCRIPT_DIR/package-manager.sh"

# Configuration
readonly PACKAGES_CONFIG="$(cd "$SCRIPT_DIR/../.." && pwd)/packages.yaml"

# Get list of available categories
get_categories() {
    if [[ ! -f "$PACKAGES_CONFIG" ]]; then
        error "Package configuration not found: $PACKAGES_CONFIG"
        return 1
    fi
    
    # Extract unique categories from all packages
    yq eval '.packages[].category' "$PACKAGES_CONFIG" 2>/dev/null | sort -u | grep -v "null"
}

# Get packages in a category
get_category_packages() {
    local category="$1"
    local platform="${2:-$(detect_platform)}"
    
    if [[ ! -f "$PACKAGES_CONFIG" ]]; then
        error "Package configuration not found: $PACKAGES_CONFIG"
        return 1
    fi
    
    # Get all packages that belong to this category and are available for this platform
    yq eval "
        .packages | 
        to_entries | 
        map(select(.value.category == \"$category\" and (.value.platforms.$platform != null or .value.platforms == null))) |
        .[].key
    " "$PACKAGES_CONFIG" 2>/dev/null | grep -v "null" || true
}

# Check if package is available for platform
is_package_available() {
    local package="$1"
    local platform="${2:-$(detect_platform)}"
    
    # Check if package exists in any category for this platform
    local categories
    mapfile -t categories < <(get_categories)
    
    for category in "${categories[@]}"; do
        local packages
        mapfile -t packages < <(get_category_packages "$category" "$platform")
        
        for pkg in "${packages[@]}"; do
            if [[ "$pkg" == "$package" ]]; then
                return 0
            fi
        done
    done
    
    return 1
}

# Install all packages in a category
install_category() {
    local category="$1"
    local platform="${2:-$(detect_platform)}"
    
    info "Installing packages for category: $category"
    
    local packages
    mapfile -t packages < <(get_category_packages "$category" "$platform")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages found for category '$category' on platform '$platform'"
        return 0
    fi
    
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        if [[ -n "$package" ]]; then
            info "Installing: $package"
            if install_package_unified "$package" "$platform"; then
                success "Installed: $package"
            else
                error "Failed to install: $package"
                failed_packages+=("$package")
            fi
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        warning "Failed to install packages: ${failed_packages[*]}"
        return 1
    fi
    
    success "Category '$category' installation complete"
}

# Install all packages for current platform
install_all_packages() {
    local platform=$(detect_platform)
    
    info "Installing all packages for platform: $platform"
    
    local categories
    mapfile -t categories < <(get_categories)
    
    local failed_categories=()
    
    for category in "${categories[@]}"; do
        if install_category "$category" "$platform"; then
            success "Category '$category' completed successfully"
        else
            error "Category '$category' had failures"
            failed_categories+=("$category")
        fi
    done
    
    if [[ ${#failed_categories[@]} -gt 0 ]]; then
        warning "Categories with failures: ${failed_categories[*]}"
        return 1
    fi
    
    success "All packages installed successfully"
}

# Interactive package selection
interactive_package_selection() {
    local platform=$(detect_platform)
    
    info "Interactive package selection for platform: $platform"
    echo
    
    local categories
    mapfile -t categories < <(get_categories)
    
    local selected_categories=()
    
    # Category selection
    echo "Available categories:"
    for i in "${!categories[@]}"; do
        local category="${categories[$i]}"
        local package_count
        package_count=$(get_category_packages "$category" "$platform" | wc -l)
        echo "  $((i+1)). $category ($package_count packages)"
    done
    echo "  a. All categories"
    echo "  q. Quit"
    echo
    
    while true; do
        read -p "Select categories to install (e.g., 1,3,5 or 'a' for all): " selection
        
        case "$selection" in
            q|Q)
                info "Installation cancelled"
                return 0
                ;;
            a|A)
                selected_categories=("${categories[@]}")
                break
                ;;
            *[0-9]*)
                # Parse comma-separated numbers
                IFS=',' read -ra ADDR <<< "$selection"
                selected_categories=()
                local valid=true
                
                for num in "${ADDR[@]}"; do
                    # Remove whitespace
                    num=$(echo "$num" | tr -d ' ')
                    
                    if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le ${#categories[@]} ]]; then
                        selected_categories+=("${categories[$((num-1))]}")
                    else
                        error "Invalid selection: $num"
                        valid=false
                        break
                    fi
                done
                
                if [[ "$valid" == "true" ]]; then
                    break
                fi
                ;;
            *)
                error "Invalid selection. Please try again."
                ;;
        esac
    done
    
    # Install selected categories
    echo
    info "Installing selected categories..."
    
    local failed_categories=()
    
    for category in "${selected_categories[@]}"; do
        if install_category "$category" "$platform"; then
            success "Category '$category' completed successfully"
        else
            error "Category '$category' had failures"
            failed_categories+=("$category")
        fi
    done
    
    if [[ ${#failed_categories[@]} -gt 0 ]]; then
        warning "Categories with failures: ${failed_categories[*]}"
        return 1
    fi
    
    success "Interactive installation complete"
}

# Show package information
show_package_info() {
    local platform=$(detect_platform)
    
    echo "Package Information for $platform:"
    echo "=================================="
    echo
    
    local categories
    mapfile -t categories < <(get_categories)
    
    for category in "${categories[@]}"; do
        local packages
        mapfile -t packages < <(get_category_packages "$category" "$platform")
        
        echo "📦 $category (${#packages[@]} packages):"
        for package in "${packages[@]}"; do
            if [[ -n "$package" ]]; then
                echo "  • $package"
            fi
        done
        echo
    done
}

# Export functions
export -f get_categories
export -f get_category_packages
export -f is_package_available
export -f install_category
export -f install_all_packages
export -f interactive_package_selection
export -f show_package_info
