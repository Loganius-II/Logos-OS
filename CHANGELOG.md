
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - 2026-09-26

Reading and writing to disk using FAT12 file system. The bootloader is now able to read the kernel from disk and load it into memory. The kernel is now able to read files from disk and display them on the screen.

### Added
- Added FAT12 filesystem support to the boot image.
- Added kernel binary to the floppy image using Mtools.
- Logical Block Addressing (LBA) support
- LBA to CHS conversion for FAT12 filesystem

### Changed
- file architecture to allow for boot and kernel to have their own directories with assembly code
- Makefile to build the bootloader and kernel separately and then combine them into a single floppy image.
### Fixed
 - FAT12 formatting issues in bootloader
 - Incorrect disk headers