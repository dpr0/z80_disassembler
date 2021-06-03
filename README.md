# Z80Disassembler

ruby Z80 disassembler

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'z80_disassembler'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install z80_disassembler

## Usage

# ruby disasm.rb filename
# prepare: sjasmplus parse.asm    - компилим исходник parse.asm в parse.C
# example: ruby disasm.rb parse.C - дизассемблируем parse.C в parse.C.txt и сравниваем с parse.txt

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/z80_disassembler. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/z80_disassembler/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Z80Disassembler project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dpr0/z80_disassembler/blob/master/CODE_OF_CONDUCT.md).
