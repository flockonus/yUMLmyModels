require 'find'
require 'rubygems'
require 'active_record'
require 'yaml'

path_rails = $*[0] rescue "."
path_models = "#{path_rails}/app/models"
database = YAML.load_file("#{path_rails}/config/database.yml")['development']
yUML = []
entidades = []
regex = /(class|set_table_name|has_many|has_one|belongs_to) +['":]?([\w:]+)['":]?(\n* *,\n* *:[\w:]+ +=> +['":]?[\w:]+['":]?| *< *[\w:]+)*/
connection = ActiveRecord::Base.establish_connection(
    :adapter  => database["adapter"],
    :host     => database["host"],
    :username => database["username"],
    :password => database["password"],
    :database => database["database"]
)

begin
  Find.find(path_models) do |path|
    next if File.basename(path)[0,1] == '.' or FileTest.directory?(path)
    entidade = {}
    file = File.open(path).readlines.join
    file.gsub(/(^|\n)=begin.*\n=end/, "").gsub!(/#.*\n/, "")
    file.gsub!(regex).each do |match|
      atributo, valor = $1.to_sym, $2
      if atributo.to_s =~ /has_many|has_one|belongs_to/
        (entidade[atributo] ||= []) << {atributo => valor}
        match.scan(/[\w:]+/).each_slice(2) do |a, v|
          entidade[atributo].last[a.gsub(/^:/, "").to_sym] = v.gsub(/^:/, "")
        end
      else
        entidade[atributo] = valor;
        entidade[:super_class] = $1 if match =~ /< *([\w:]+)/
      end
      match
    end

    if entidade[:super_class] == "ActiveRecord::Base"
      eval <<-EOF
        class Entidade < #{entidade[:super_class]}
          #{"set_table_name :" + entidade[:set_table_name] if entidade[:set_table_name]}
        end
        entidade[:attributes] = Entidade.new.attribute_names
      EOF
    end

    entidades << entidade
    print "#{entidade.inspect}\n\n"
  end

  entidades.each do |entidade|
    yUML << "[#{entidade[:class]}|#{entidade[:attributes] * ";" if entidade[:attributes]}]"
    if not entidade[:super_class].nil? and entidade[:super_class] != "ActiveRecord::Base"
      yUML << "[#{entidade[:class]}]^[#{entidade[:super_class]}]"
    end
    entidade[:has_many] and entidade[:has_many].each do |relacao|
      yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || relacao[:has_many]}]"
    end
  end

  p yUML.join(",")
rescue Exception => e
  print "ERRROR: \n#{e}\n"
end
