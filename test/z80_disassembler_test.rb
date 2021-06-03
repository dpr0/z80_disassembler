# frozen_string_literal: true

require 'test_helper'

class Z80DisassemblerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Z80Disassembler::VERSION
  end

  def test_parse
    ::Z80Disassembler::Disassembler.new('test/parse.C').start
    assert_equal File.read('test/parse.txt'), File.read('test/parse.C.txt')
  end

  def test_error
    ::Z80Disassembler::Disassembler.new('test/error.C').start
    assert_equal File.read('test/error.txt'), File.read('test/error.C.txt')
  end
end
