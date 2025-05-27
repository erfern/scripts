#!/usr/bin/bash

SIZE="8G"
DEVICE="/dev/zram0"
ALGORITHM="zstd"
PRIORITY=100

tweak_memory_related_settings() {
  sysctl vm.swappiness=60  # 180
  sysctl vm.watermark_boost_factor=0
  sysctl vm.watermark_scale_factor=125
  sysctl vm.page-cluster=0
}

setup_zram() {
  modprobe zram
  until [[ -b "$DEVICE" ]]; do sleep 1; done
  zramctl $DEVICE --algorithm $ALGORITHM --size "$SIZE"
}

activate_zram_swap() {
  mkswap -U clear $DEVICE
  swapon --discard --priority $PRIORITY $DEVICE
}

tweak_memory_related_settings
setup_zram
activate_zram_swap
