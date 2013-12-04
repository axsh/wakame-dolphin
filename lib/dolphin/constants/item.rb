# -*- coding: utf-8 -*-

module Dolphin::Constants
  module Item
    ITEMS = {
      'CPU1' => 'CPU1',
      'CPU2' => 'CPU2',
      'CPU3' => 'CPU3',
      'MEMORY' => 'MEMORY',
      'DISK1' => 'vfs.fs.size[{$DISK1},pused]',
      'DISK2' => 'vfs.fs.size[{$DISK2},pused]',
      'DISK3' => 'vfs.fs.size[{$DISK3},pused]',
      'DISK4' => 'vfs.fs.size[{$DISK4},pused]',
      'DISK5' => 'vfs.fs.size[{$DISK5},pused]',
      'SWAP' => 'system.swap.size[,pused]',
      'LOADAVERAGE1' => 'LOADAVERAGE1',
      'LOADAVERAGE2' => 'LOADAVERAGE2',
      'LOADAVERAGE3' => 'LOADAVERAGE3',
      'PROCESS1' => 'proc.num[,,,{$PROCESS1}]',
      'PROCESS2' => 'proc.num[,,,{$PROCESS2}]',
      'PROCESS3' => 'proc.num[,,,{$PROCESS3}]',
      'PROCESS4' => 'proc.num[,,,{$PROCESS4}]',
      'PROCESS5' => 'proc.num[,,,{$PROCESS5}]',
      'PROCESS6' => 'proc.num[,,,{$PROCESS6}]',
      'PROCESS7' => 'proc.num[,,,{$PROCESS7}]',
      'PROCESS8' => 'proc.num[,,,{$PROCESS8}]',
      'PROCESS9' => 'proc.num[,,,{$PROCESS9}]',
      'PROCESS10' => 'proc.num[,,,{$PROCESS10}]',
      'PORT1' => 'tcp,{$PORT1}',
      'PORT2' => 'tcp,{$PORT2}',
      'PORT3' => 'tcp,{$PORT3}',
      'PORT4' => 'tcp,{$PORT4}',
      'PORT5' => 'tcp,{$PORT5}',
      'PORT6' => 'tcp,{$PORT6}',
      'PORT7' => 'tcp,{$PORT7}',
      'PORT8' => 'tcp,{$PORT8}',
      'PORT9' => 'tcp,{$PORT9}',
      'PORT10' => 'tcp,{$PORT10}',
      'PING' => 'icmpping[{$IPADRESS1},,,,1000]',
    }.freeze

  end
end
