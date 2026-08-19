#!/usr/bin/env ruby

ARGF.each do |line|
  dir, author, date = line.chomp.split(/\t/)
  author.gsub!("-", " ")
  if File.directory?(dir)
    open("#{dir}/metadata.tex", 'w') do |f|

      f.puts("\\modauthor{#{author}}")
      f.puts("\\moddate{#{date}}")
    end
  end
end
