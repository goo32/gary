#!/usr/bin/env ruby

# Requires an implementation for BinPacker and BinUnpacker

def compress(original)
  tree = build_tree(original)
  table = build_table(tree)
  packer = BinPacker.new

  packer.int32(original.length)
  pack_table(table, packer)

  original.bytes do |byte|
    bits = look_up_byte(table, byte)
    packer.bits(bits)
  end

  packer.pack
end

def decompress(compressed)
  unpacker = BinUnpacker.new(compressed)  

  data_length = unpacker.int32
  table = unpack_table(unpacker)

  data_length.times.map do
    look_up_bits(table, unpacker)
  end.map(&:chr).join
end

def build_tree(original)
  bytes = original.bytes
  unique_bytes = bytes.uniq

  nodes = unique_bytes.map do |byte|
    count = bytes.count(byte)
    Leaf.new(byte, count)
  end

  until nodes.length == 1
    node1 = nodes.delete(nodes.min_by(&:count))
    node2 = nodes.delete(nodes.min_by(&:count))
    nodes << Node.new(node1, node2, node1.count + node2.count)
  end

  nodes[0]
end

# a = 00
# b = 01
# c = 1
def build_table(node, path=[])
  if node.is_a? Node
    build_table(node.left, path + [0]) + 
      build_table(node.right, path + [1])
  else
    [TableRow.new(node.byte, path)]
  end
end

def look_up_byte(table, byte)
  table.each do |row|
    if row.byte == byte
      return row.bits
    end
  end

  throw "Should not get here"
end

def look_up_bits(table, upacker)
  table.each do |row|
    if row.bits == unpacker.peek(row.bits.length)
      unpacker.bits(row.bits.length)
      return row.byte
    end
  end

  throw "Should not get here"
end

def pack_table(table, packer)
  packer.int8(table.length)
  table.each do |row|
    packer.int8(row.byte)
    packer.int8(row.bits.length)
    packer.bits(row.bits)
  end  
end

def unpack_table(unpacker)
  table_length = unpacker.int8
  table_length.times.map do
    byte = unpacker.int8
    bit_length = unpacker.int8
    bits = unpacker.bits(bit_length)
    TableRow.new(byte, bits)
  end
end

Node = Struct.new(:left, :right, :count)
Leaf = Struct.new(:byte, :count)

TableRow = Struct.new(:byte, :bits)

compressed = compress "abbcccc"
p compressed
p compressed.length

decompressed = decompress compressed
p decompressed
p decompressed.length