# frozen_string_literal: true

require_relative 'z80_disassembler/version'

module Z80Disassembler
  class Error < StandardError; end

  class Disassembler
    attr_reader :org, :file_size, :rmda

    #             0       1       2       3       4       5       6       7
    T_R   = [    'B',    'C',    'D',    'E',    'H',    'L', '(HL)',    'A'].freeze
    T_CC  = [   'NZ',    'Z',   'NC',    'C',   'PO',   'PE',    'P',    'M'].freeze
    T_ALU = [  'ADD',  'ADC',  'SUB',  'SBC',  'AND',  'XOR',   'OR',   'CP'].freeze
    T_ROT = [  'RLC',  'RRC',   'RL',   'RR',  'SLA',  'SRA',  'SLL',  'SRL'].freeze
    T_IM  = [    '0',  '0/1',    '1',    '2',    '0',  '0/1',    '1',    '2'].freeze
    T_RP  = [   'BC',   'DE',   'HL',   'SP'].freeze
    T_RP2 = [   'BC',   'DE',   'HL',   'AF'].freeze
    ASCII = [
      ' ', '!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/',
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=', '>', '?',
      '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
      'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[', '\\',']', '^', '_',
      '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
      'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '{', '|', '}', '~'
    ].freeze

    def initialize(file, org = 32_768)
      @file = file; @org = org.to_i
      if file.original_filename[-3..-1] == '.$C'
        File.open(@file) do |f|
          z = f.read(17)
          @file_name   = "#{z[0..7]}.#{z[8]}"
          @org         = bytes_to_int(z[ 9..10])
          @file_size   = bytes_to_int(z[11..12])
          @sectors     = bytes_to_int(z[13..14])
          checksum1    = bytes_to_int(z[15..16])
          checksum2    = (z[0..14].sum * 257 + 105).to_s(16)[-4..-1].hex
          @code        = f.read(@file_size).bytes if checksum1 == checksum2
        end
      end
      @code ||= File.open(@file).read.bytes
      @file_size ||= @file.size
      @x = 0; @y = 0; @z = 0; @p = 0; @q = 0; @xx = nil
      @lambda = nil; @prefix = nil; @prev = nil
      @hash_links = {}; @del_links = []
      @rmda = """
        ;--- #{Date.today} --- https://rmda.su
        ;    _______  _/| __ ______    ____
        ;   /  __   //  |/  \\\\   _  \\ /    \\
        ;  /   _/ _//        \\\\  \\\\  \\\\  \\  \\
        ;  \\___\\   \\\\___\\/___//______//__/\\__\\
        ;       \\__/
        ;--- size: #{@file_size}b --- filename: #{@file_name}

      """
    end

    def start
      result = []
      addr = @org
      bytes = []; ascii = []
      @code.each do |byte|
        load_vars(byte)
        str = command_from_byte(byte)
        @prev = byte.to_s(16)
        ascii << ((32..126).include?(byte) ? ASCII[byte - 32] : ' ')
        bytes << @prev.rjust(2, '0').upcase
        next unless str

        result << [addr, "##{addr.to_s(16)}".upcase, str, bytes.join(' '), ascii.join]
        addr += bytes.size
        bytes = []
        ascii = []
      end

      link_num = 0
      int_addrs = @org..(@org + @file_size)
      result.select { |z| z[2] =~ /#[0-F]{4}/ && int_addrs.include?(z[2].split('#').last[0..3].hex) }.each do |x|
        z = "##{x[2].split('#').last[0..3]}"
        @hash_links[z] = "link_#{link_num += 1}" unless @hash_links[z]
      end
      result.select { |z| z[2] =~ /\$/ }.each do |x|
        z = "##{ (x[0] + x[2].split('$').last.to_i).to_s(16).upcase }"
        @hash_links[z] = "link_#{link_num += 1}" unless @hash_links[z]
      end
      code = result.map do |addr_, addr16, str, bytes_, ascii_|
        @del_links << @hash_links[addr16] if @hash_links[addr16]
        link = (@hash_links[addr16] ? (@hash_links[addr16] + ':') : '').ljust(16, ' ')
        substr, adr = if str.include?('$')
                        ["$#{str.split('$').last}", "##{(addr_ + str.split('$').last.to_i).to_s(16).upcase}"]
                      else
                        adr = "##{str.split('#').last[0..3]}"
                        [adr, adr]
                      end
        string = @hash_links.keys.include?(adr) ? str.sub(substr, @hash_links[adr]) : str

        defb = bytes_.split(" ").map { |x| "##{x}"}.join(",")
        "#{link} #{string.ljust(16, ' ')}; #{addr16.ljust(5, ' ')} / #{addr_.to_s.ljust(5, ' ')} ; #{ascii_.ljust(4, ' ')} ; #{defb}"
      end.join("\n")
      [
          *@rmda,
          '                 device zxspectrum128',
          '                 ORG #' + @org.to_s(16),
          @hash_links.map { |key, val| "#{(val + ':').ljust(16, ' ')} EQU #{key}" unless @del_links.include?(val) }.compact.join("\n"),
          'begin:',
          code,
          'end:',
          ''
      ].join("\n")
    end

    def self.compile_text(file_name)
      [
        'length equ end - begin',
        'CODE      = #AF',
        'USR       = #C0',
        'LOAD      = #EF',
        'CLEAR     = #FD',
        'RANDOMIZE = #F9',
        '        org #5C00',
        'baszac  db 0,1',    # Line number
        '        dw linlen', # Line length
        'linzac  db CLEAR, "8", #0E, 0, 0',
        '        dw begin - 1',
        '        db 0, ":"',
        '        db LOAD, "\""',
        'codnam  ds 10, 32',
        '        org codnam',
        '        db "disasm"',
        '        org codnam + 10',
        '        db "\"", CODE, ":"',
        '        db RANDOMIZE, USR, "8", #0E, 0, 0',
        '        dw begin',  # call address
        '        db 0, #0D',
        'linlen = $ - linzac',
        'baslen = $ - baszac',
        "        emptytap '#{file_name}.tap'",
        "        savetap '#{file_name}.tap', BASIC, '#{file_name}', baszac, baslen, 1",
        "        savetap '#{file_name}.tap', CODE,  '#{file_name}', begin,  length, begin",
        "        savesna '#{file_name}.sna', begin",
        "        savebin '#{file_name}.C',   begin, length",
        "        savehob '#{file_name}.$C', '#{file_name}.C', begin, length",
        ''
      ].join("\n")
    end

    private

    def bytes_to_int(array)
      array.bytes.reverse.map { |x| x.to_s(16).rjust(2, '0') }.join.hex
    end

    def command_from_byte(byte)
      case @prefix
      when 'cb' then @prefix = nil; cb_prefix
      when 'ed' then @prefix = nil; ed_prefix(byte)
      when 'dd' then @xx = 'IX'; xx_prefix(byte)
      when 'fd' then @xx = 'IY'; xx_prefix(byte)
      when 'xx' then temp = @temp; @temp = nil; displacement(byte, temp)
      when 2    then @prefix -= 1; @temp = byte.to_s(16).rjust(2, '0').upcase; nil
      when 1
        resp = @lambda.call(@arg, byte.to_s(16).rjust(2, '0').upcase)
        @prefix = nil; temp = @temp; @temp = nil
        if temp && resp.include?('(HL)')
          @xx ? resp = displacement(temp.hex, resp) : resp += temp
        elsif temp && resp.include?(')')
          # resp = displacement(temp.hex, resp) if @xx
          resp = resp.sub(')', "#{temp})").sub('(', '(#')
        elsif temp
          resp += temp
        end
        resp = hl_to_xx(resp, @xx) unless @xx.nil?
        if resp.include?('JR') || resp.include?('DJNZ')
          z = resp.split('#')
          z[1] = z[1].hex < 127 ? "$+#{z[1].hex + 2}" : "$-#{255 - z[1].hex - 1}"
          resp = z.join
        end
        resp
      else command
      end
    end

    def hl_to_xx(temp, reg)
      @xx = nil
      if temp.include?('HL')
        temp.sub('HL', reg)
      elsif temp.include?(' L')
        temp.sub(' L', " #{reg}L")
      elsif temp.include?(',L')
        temp.sub(',L', ",#{reg}L")
      elsif temp.include?(' H')
        temp.sub(' H', " #{reg}H")
      elsif temp.include?(',H')
        temp.sub(',H', ",#{reg}H")
      else
        temp
      end
    end

    def displacement(byte, temp)
      @prefix = nil
      byte -= 256 if byte > 127
      des = ['+0', "+#{byte}", byte.to_s][byte <=> 0]
      temp.sub('HL', @xx + des)
    end

    def load_vars(byte)
      bin = byte.to_s(2).rjust(8, '0')
      @x = bin[0..1].to_i(2)
      @y = bin[2..4].to_i(2)
      @z = bin[5..7].to_i(2)
      @p = bin[2..3].to_i(2)
      @q = bin[4] == '1'
    end

    def command
      case @x
      when 0
        case @z
        when 0
          case @y
          when 0 then 'NOP'
          when 1 then 'EX AF, AF\''
          when 2 then calc_bytes(->(a, b){ "DJNZ ##{b}"    }, nil,          1)
          when 3 then calc_bytes(->(a, b){ "JR ##{b}"      }, nil,          1)
          else        calc_bytes(->(a, b){ "JR #{a},##{b}" }, T_CC[@y - 4], 1)
          end
        when 1 then @q ? "ADD HL,#{T_RP[@p]}" : calc_bytes(->(a, b){ "LD #{a},##{b}" }, T_RP[@p], 2)
        when 2
          a1 = @p == 2 ? 'HL' : 'A'
          if @p > 1
            calc_bytes((@q ? ->(a, b){ "LD #{a},(#{b})" } : ->(a, b){ "LD (#{b}),#{a}" }), a1, 2)
          else
            a2 = ['(BC)','(DE)'][@p]
            'LD ' + (@q ? "#{a1},#{a2}" : "#{a2},#{a1}")
          end
        when 3 then "#{@q ? 'DEC' : 'INC'} #{T_RP[@p]}"
        when 4 then "INC #{T_R[@y]}"
        when 5 then "DEC #{T_R[@y]}"
        when 6 then calc_bytes(->(a, b){ "LD #{a},##{b}" }, T_R[@y], 1)
        when 7 then ['RLCA','RRCA','RLA','RRA','DAA','CPL','SCF','CCF'][@y]
        end
      when 1 then @z == 6 && @y == 6 ? 'HALT' : "LD #{T_R[@y]},#{T_R[@z]}"
      when 2 then "#{T_ALU[@y]} #{T_R[@z]}"
      when 3
        case @z
        when 0 then "RET #{T_CC[@y]}"
        when 1 then @q ? ['RET','EXX','JP HL','LD SP, HL'][@p] : "POP #{T_RP2[@p]}"
        when 2 then calc_bytes(->(a, b){ "JP #{a},##{b}" }, T_CC[@y], 2)
        when 3
          case @y
          when 0 then calc_bytes(->(a, b){ "JP ##{b}" }, nil, 2)
          when 1 then @prefix = 'cb'; nil
          when 2 then calc_bytes(->(a, b){ "OUT (##{b}),A" }, nil, 1)
          when 3 then calc_bytes(->(a, b){ "IN A,(##{b})" }, nil, 1)
          when 4 then 'EX (SP),HL'
          when 5 then 'EX DE,HL'
          when 6 then 'DI'
          when 7 then 'EI'
          end
        when 4 then calc_bytes(->(a, b){ "CALL #{a},##{b}" }, T_CC[@y], 2)
        when 5
          if @q
            case @p
            when 0 then calc_bytes(->(a, b){ "CALL ##{b}" }, nil, 2)
            when 1 then @prefix = 'dd'; nil
            when 2 then @prefix = 'ed'; nil
            when 3 then @prefix = 'fd'; nil
            end
          else
            "PUSH #{T_RP2[@p]}"
          end
        when 6 then calc_bytes(->(a, b){ "#{a} ##{b}" }, T_ALU[@y], 1)
        when 7 then "RST #{@y * 8}"
        end
      end
    end

    def calc_bytes(lambda, arg, prefix)
      @lambda, @arg, @prefix = lambda, arg, prefix; nil
    end

    def xx_prefix(_byte) # dd fd prefix
      @temp = command
      if @temp&.include?('(')
        @prefix = 'xx'; nil
      elsif ['dd', 'fd'].include?(@prev) && @temp
        temp = @temp; @temp = nil; @prefix = nil
        hl_to_xx(temp, @xx)
      elsif @lambda && !@arg&.include?('HL')
        @prefix = 1; @temp
      else
        @prefix = 2; @temp
      end
    end

    def cb_prefix
      ["#{T_ROT[@y]} ", "BIT #{@y},", "RES #{@y},", "SET #{@y},"][@x] + T_R[@z]
    end

    def ed_prefix(byte)
      if @x == 1
        case @z
        when 0 then "IN #{"#{T_R[@y]}," if @y != 6}(C)"
        when 1 then "OUT (C),#{@y == 6 ? 0 : T_R[@y]}"
        when 2 then "#{@q ? 'ADC' : 'SBC'} HL,#{T_RP[@p]}"
        when 3 then calc_bytes((@q ? ->(a, b){ "LD #{a},(#{b})" } : ->(a, b){ "LD (#{b}),#{a}" }), T_RP[@p], 2)
        when 4 then 'NEG'
        when 5 then @y == 1 ? 'RETI' : 'RETN'
        when 6 then "IM #{T_IM[@y]}"
        when 7 then ['LD I,A','LD R,A','LD A,I','LD A,R','RRD','RLD','NOP','NOP'][@y]
        end
      elsif @x == 2 && @z <= 3 && @y >= 4
        [['LDI','CPI','INI','OUTI'],['LDD','CPD','IND','OUTD'],['LDIR','CPIR','INIR','OTIR'],['LDDR','CPDR','INDR','OTDR']][@y - 4][@z]
      else
        "#{'DB #ED'}, ##{byte.to_s(16).rjust(2, '0').upcase}"
      end
    end
  end
end
