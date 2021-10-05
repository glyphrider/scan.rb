require 'bundler'
require 'readline'
require 'nokogiri'
require 'open-uri'

results = [];

def recurse(parser,name,list)
  #puts "calling recurse for #{name}"
  parser.specs.each { |spec|
    if spec.name == name && list.index(name) == nil
      list.push(name)
      puts "  #{spec.name} --> #{spec.version}"
      spec.dependencies.each { |dep|
        #puts "dep #{dep.inspect}"
        list = recurse(parser,dep.name,list)
      }
    end
  }
  return list
end

while file_name = Readline.readline
  directory = File.dirname(File.expand_path(file_name))
  Dir.chdir(directory) { | path |
    puts "now in directory #{path}"
    rt = Bundler::Runtime::new(Dir.getwd,Bundler::Definition::build(Bundler::default_gemfile,Bundler::default_lockfile,false))
    parser = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))

    results = []

    parser.specs.each { |spec|
      #puts "spec-source: #{spec.name} --> #{spec.source}"
      url = "https://rubygems.org/gems/#{spec.name}/versions/#{spec.version}"
      result = { filename: file_name, path: path, name: spec.name, version: spec.version , url: url }

      puts "  scanning --> #{url}"
      begin
        page = Nokogiri::HTML(URI.open(url))
        p = page.xpath("//span//p")
        if p == nil
          license = "Unknown"
          result[:url] = ""
        else
          #puts "p --> #{p.inspect}"
          license = p[0].children[0].content
          result[:license] = license
        end
          result[:license] = license
      rescue
        puts "--- not a rubygems asset (#{spec.name})"
        #puts "--- #{spec.inspect}"
        result[:license] = "VHT"
      end

      results.push(result)
    }
  }
end

File.open("gems.html","w") { |f|
  f.write "<html><head><title>gems</title></head><body><div class=\"list\">\n"

  results.each { |result|
    f.write "<div class=\"listing\"><a href=\"#{result[:url]}\">#{result[:name]}</a> (#{result[:version]}) - #{result[:license]} - #{result[:filename]}</div>\n"
  }
  f.write "</div></body></html>\n"
}

File.open("gems.csv","w") { |f|
  f.write "\"Name\",\"Version\",\"License\",\"Gemfile.lock\",\"URL\"\n"
  results.each { |result|
    f.write "\"#{result[:name]}\",\"#{result[:version]}\",\"#{result[:license]}\",\"#{result[:filename]}\",\"#{result[:url]}\"\n"
  }
}
