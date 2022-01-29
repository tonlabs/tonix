pragma ton-solidity >= 0.56.0;

import "../include/Internal.sol";

/* Common functions and definitions for file system handling and synchronization */
abstract contract SyncFS is Internal {

    mapping (uint16 => Inode) _inodes;
    mapping (uint16 => bytes) public _data;
    uint16 _block_size;
    uint16 _device_id;

    function get_inodes() external view returns (mapping (uint16 => Inode) inodes) {
        inodes = _inodes;
    }

    function init_fs(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external accept {
        _inodes = inodes;
        _data = data;
        _device_id = inodes[sb.SB_INFO].device_id;
        _block_size = inodes[sb.SB_INFO].n_blocks;
    }

    function apply_changes(mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external accept {
        for ((uint16 index, Inode inode): inodes)
            _inodes[index] = inode;
        for ((uint16 index, bytes bts): data)
            _data[index] = bts;
    }
}