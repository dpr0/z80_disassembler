# frozen_string_literal: true

require 'test_helper'

class Z80DisassemblerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Z80Disassembler::VERSION
  end

  def test_parse
    resp = ::Z80Disassembler::Disassembler.new('test/parse.C').start
    hash = {
      32768 => ['#8000', 'LD IXL,#04',  'DD 2E 04', '_._'],
      32771 => ['#8003', 'LD L,(IX)',   'DD 6E 00', '_n_'],
      32774 => ['#8006', 'LD H,(IX+1)', 'DD 66 01', '_f_'],
      32777 => ['#8009', 'LD A,#04',    '3E 04',    '>_' ],
      32779 => ['#800B', 'LD HL,#5800', '21 00 58', '!_X'],
      32782 => ['#800E', 'LD DE,#5801', '11 01 58', '__X'],
      32785 => ['#8011', 'LD BC,#02FF', '01 FF 02', '___'],
      32788 => ['#8014', 'LD (HL),A',   '77',       'w'  ],
      32789 => ['#8015', 'LDIR',        'ED B0',    '__' ],
      32791 => ['#8017', 'RET',         'C9',       '_'  ]
    }

    assert_equal hash, resp
  end
end
