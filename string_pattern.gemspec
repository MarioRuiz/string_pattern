Gem::Specification.new do |s|
  s.name        = 'string_pattern'
  s.version     = '2.0.0'
  s.summary     = "Generate easily random strings following a simple pattern or regular expression. '10-20:Xn/x/'.generate #>qBstvc6JN8ra"
  s.description = "You can easily generate strings supplying a very simple pattern. '10-20:Xn/x/'.generate #>qBstvc6JN8ra. Now generate random strings using a regular expression (Regexp): /[a-z0-9]{2,5}\w+/.gen . Also, you can validate if a text fulfills a specific pattern or even generate a string following a pattern and returning the wrong length, value... for testing your applications."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = ["lib/string_pattern.rb","lib/string/pattern/add_to_ruby.rb","LICENSE","README.md",".yardopts"]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/string_pattern'
  s.license       = 'MIT'
  s.add_runtime_dependency 'regexp_parser', '~> 1.3', '>= 1.3.0'
end

