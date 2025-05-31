#!/bin/bash

# SOURCE_DIR="/path/to/source/folder"
# DEST_DIR="/path/to/destination/folder"
# EXTENSION="bin"  # Change this to the file extension you're looking for (e.g., bin, hex, etc.)
#
# LATEST_FILE_LEFT=$(find . -type f -name "*left.uf2" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2)
# LATEST_FILE_RIGHT=$(find . -type f -name "*right.uf2" -printf "%T@ %p\n" | sort -n | tail -1 | cut -d' ' -f2)
#
# echo "latest left file: $LATEST_FILE"


# Set the firmware directory and the mount point
FIRMWARE_DIR="./firmware"
MOUNT_POINT="/mnt/keyboard"
MOUNTED=0

# trap 'echo "Unmounting on exit..."; sudo umount "$MOUNT_POINT" 2>/dev/null' EXIT
trap 'if [[ $MOUNTED -eq 1 ]]; then echo "Unmounting..."; sudo umount "$MOUNT_POINT"; fi' EXIT

# Prompt for the device name
read -p "Enter the device name (e.g., sdX1): " DEVICE_NAME

# Validate the device input
# if [ ! -b "/dev/$DEVICE_NAME" ]; then
#     echo "Error: /dev/$DEVICE_NAME is not a valid block device or does not exist. Exiting."
#     exit 1
# fi

# Prompt for the side (left or right)
read -p "Enter the side to flash (left/right): " SIDE

# Validate the side input
if [[ "$SIDE" != "left" && "$SIDE" != "right" ]]; then
    echo "Invalid side entered. Please enter 'left' or 'right'. Exiting."
    exit 1
fi

# Check if mount point is removable
if ! lsblk -no RM "/dev/${DEVICE_NAME%[0-9]*}" | grep -q 1; then
    echo "Warning: /dev/$DEVICE_NAME may not be a removable device. Aborting for safety."
    exit 1
fi

# Check if the mount point exists
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Mount point $MOUNT_POINT does not exist. Creating it..."
    mkdir -p "$MOUNT_POINT"
fi

# Check if mount point is already mounted
# mount | grep -q "/dev/$DEVICE_NAME"
# if [ $? -eq 0 ]; then
#     echo "/dev/$DEVICE_NAME is already mounted. Exiting to avoid double-mounting."
#     exit 1
# fi
findmnt -rn -S "/dev/$DEVICE_NAME" > /dev/null
if [ $? -eq 0 ]; then
    echo "/dev/$DEVICE_NAME is already mounted. Exiting."
    exit 1
fi

# Mount the keyboard
echo "Mounting the keyboard..."
# echo "RUNNING: sudo mount /dev/$DEVICE_NAME $MOUNT_POINT"
sudo mount /dev/"$DEVICE_NAME" "$MOUNT_POINT" && MOUNTED=1

# Check for successful mount
if [ $? -ne 0 ]; then
    echo "Failed to mount the keyboard. Exiting."
    exit 1
fi

# Get the most recent file from the firmware directory
# LATEST_FILE=$(ls -t "$FIRMWARE_DIR"/*-${SIDE}.uf2 2>/dev/null | head -n 1)
LATEST_FILE=$(ls -t "$FIRMWARE_DIR"/*-${SIDE}-clique.uf2 2>/dev/null | head -n 1)
# ls -t "$FIRMWARE_DIR"/*-left-clique.uf2 2>/dev/null | head -n 1

# Check if a file was found
if [ -z "$LATEST_FILE" ]; then
    echo "No firmware file found for side '$SIDE'. Exiting."
    # echo "RUNNING: sudo umount $MOUNT_POINT"
    sudo umount "$MOUNT_POINT"
    exit 1
fi

# Copy the latest firmware file to the mount point
echo "Copying $LATEST_FILE to $MOUNT_POINT..."
# echo "RUNNING: cp $LATEST_FILE $MOUNT_POINT"
sudo cp "$LATEST_FILE" "$MOUNT_POINT"

# Inform the user that copying the file is complete
echo "Firmware file copied. Please wait for the flashing process to complete."

# Wait for user to press any key to unmount
read -n 1 -s -r -p "Press any key to unmount the keyboard and after the flashing process is complete"

# Confirm unmounting
read -p "Are you sure you want to unmount the keyboard? (y/n): If you say no, the script will exit and not run umount" CONFIRM_UNMOUNT

if [[ "$CONFIRM_UNMOUNT" != "y" ]]; then
    echo "Unmounting cancelled. Exiting."
    exit 0
fi

# Unmount the keyboard
echo "Unmounting the keyboard..."
# echo "RUNNING: sudo umount $MOUNT_POINT"
sudo umount "$MOUNT_POINT"

# Completion message
echo "Firmware file copied and keyboard unmounted successfully."

