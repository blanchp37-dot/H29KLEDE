#!/bin/bash
# set -ex

# List of kernel versions to check
KERNEL_VERSIONS=("6, 6, 0" "6, 8, 0" "6, 9, 0" "6, 10, 0" "6, 11, 0")

modify_file() {
  local file=$1

  # OpenWrt 24.10 (Linux 6.6) doesn't have WQ_BH
  if [[ "$file" == "./usb.c" || "$file" == "./usb.h" ]]; then
    echo "Skipping file: $file"
    return
  fi
  
  # Check if file exists
  if [[ -f "$file" ]]; then
    echo "Processing file: $file"

    for version in "${KERNEL_VERSIONS[@]}"; do
      # Update first pattern
      sed -i "s/#if LINUX_VERSION_CODE < KERNEL_VERSION(${version})/#if LINUX_VERSION_CODE < KERNEL_VERSION(${version}) \&\& !defined(OPENWRT)/" "$file"
      sed -i "s/#if (LINUX_VERSION_CODE < KERNEL_VERSION(${version}))/#if (LINUX_VERSION_CODE < KERNEL_VERSION(${version})) \&\& !defined(OPENWRT)/" "$file"
      
      # Update second pattern
      sed -i "s/#if LINUX_VERSION_CODE >= KERNEL_VERSION(${version})/#if LINUX_VERSION_CODE >= KERNEL_VERSION(${version}) || defined(OPENWRT)/" "$file"
      sed -i "s/#if (LINUX_VERSION_CODE >= KERNEL_VERSION(${version}))/#if (LINUX_VERSION_CODE >= KERNEL_VERSION(${version})) || defined(OPENWRT)/" "$file"
    done

    echo "Modifications applied to $file"
  else
    echo "File not found: $file"
  fi
}

patch_rtw88_main_h() {
  local file="main.h"
  
  # Check if the file exists
  if [[ -f "$file" ]]; then
    echo "Patching file: $file"

    # Check if the '#define OPENWRT' line is already present
    if ! grep -q "#define OPENWRT" "$file"; then
      sed -i '39i\
#define OPENWRT\n' "$file"

      echo "Patched $file with '#define OPENWRT'"
    else
      echo "File $file already contains '#define OPENWRT', skipping patch."
    fi
  else
    echo "File not found: $file"
  fi
}

# Find all files in the current directory and subdirectories to modify.
# find . -type f -name "*.c" -o -name "*.h" | while read -r file; do
# Do not replace alt_rtl8821ce/ files.
find . -type d -name "alt_rtl8821ce" -prune -o \( -type f -name "*.c" -o -name "*.h" \) -print | while read -r file; do
  modify_file "$file"
done

patch_rtw88_main_h

echo "Finished."
