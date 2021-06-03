# frozen_string_literal: true

require 'test_helper'

class Z80DisassemblerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Z80Disassembler::VERSION
  end

  def test_parse
    resp = ::Z80Disassembler::Disassembler.new('test/parse.C').start
    hash = {
      32_768 => ['#8000', 'LD IXL,#04',  'dd 2e 04'],
      32_771 => ['#8003', 'LD L,(IX)',   'dd 6e 00'],
      32_774 => ['#8006', 'LD H,(IX+1)', 'dd 66 01'],
      32_777 => ['#8009', 'LD A,#04',    '3e 04'   ],
      32_779 => ['#800B', 'LD HL,#5800', '21 00 58'],
      32_782 => ['#800E', 'LD DE,#5801', '11 01 58'],
      32_785 => ['#8011', 'LD BC,#02FF', '01 ff 02'],
      32_788 => ['#8014', 'LD (HL),A',   '77'      ],
      32_789 => ['#8015', 'LDIR',        'ed b0'   ],
      32_791 => ['#8017', 'RET',         'c9'      ]
    }
    assert_equal hash, resp
  end
end
