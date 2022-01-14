Gem::Specification.new do |s|
  s.name        = 'string_pattern'
  s.version     = '2.2.3'
  s.summary     = "Generate easily random strings following a simple pattern or regular expression. '10-20:Xn/x/'.generate #>qBstvc6JN8ra. Also generate words in English or Spanish. Perfect to be used in test data factories."
  s.description = "Easily generate strings supplying a very simple pattern. '10-20:Xn/x/'.generate #>qBstvc6JN8ra. Generate random strings using a regular expression (Regexp): /[a-z0-9]{2,5}\w+/.gen . Also generate words in English or Spanish. Perfect to be used in test data factories. Also, validate if a text fulfills a specific pattern or even generate a string following a pattern and returning the wrong length, value... for testing your applications."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = ["lib/string_pattern.rb","lib/string/pattern/add_to_ruby.rb", "lib/string/pattern/analyze.rb",
                   "lib/string/pattern/generate.rb", "lib/string/pattern/validate.rb",
                   "LICENSE","README.md",".yardopts",
                  'data/english/adjs.json', 'data/english/nouns.json', 'data/spanish/palabras0.json',
                  'data/spanish/palabras1.json','data/spanish/palabras2.json','data/spanish/palabras3.json',
                  'data/spanish/palabras4.json','data/spanish/palabras5.json','data/spanish/palabras6.json',
                  'data/spanish/palabras7.json','data/spanish/palabras8.json','data/spanish/palabras9.json',
                  'data/spanish/palabras10.json','data/spanish/palabras11.json',]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/string_pattern'
  s.license       = 'MIT'
  s.add_runtime_dependency 'regexp_parser', '~> 1.3', '>= 1.3.0'
end

