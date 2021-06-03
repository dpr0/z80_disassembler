# frozen_string_literal: true

require_relative 'lib/z80_disassembler/version'

Gem::Specification.new do |spec|
  spec.name          = 'z80_disassembler'
  spec.version       = Z80Disassembler::VERSION
  spec.authors       = ['dvitvitskiy']
  spec.email         = ['dvitvitskiy.pro@gmail.com']
  spec.summary       = 'Ruby ZILOG Z80 disassembler'
  spec.homepage      = ''
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
end
