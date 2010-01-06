require 'find'
require 'rubygems'
require 'active_record' rescue require 'activerecord'
#gem 'activesupport'
#  require 'inflector_portuguese.rb'
require 'yaml'


t1 = Time.now

path_rails = $*[0] rescue "."

atributos, sozinhas = false
ARGV[1,12].each do |arg|
  case arg
    when 'atributos' then
      atributos = true;
      break
    when 'sozinhas' then
      sozinhas = true;
      break
    end
end




path_models = "#{path_rails}/app/models"
yUML = []
entidades = []
regex = /(class|set_table_name|has_many|has_many_with_attributes|has_one|belongs_to) +['":]?([\w:]+)['":]?(\n* *,\n* *:[\w:]+ +=> *['":]?[\w:]+['":]?| *< *[\w:]+)*/

if atributos
  database = YAML.load_file("#{path_rails}/config/database.yml")['development']
  connection = ActiveRecord::Base.establish_connection(
      :adapter  => database["adapter"],
      :host     => database["host"],
      :username => database["username"],
      :password => database["password"],
      :database => database["database"]
  )
end

def extrai_name_space(str, qualidade = :first)
    
  if str.include?(':')
    if qualidade == :full
      str = str[0..str.rindex(':') -2]
      
    elsif qualidade == :first
      str = str[0..str.index(':') -1]
    end
  else
    str = str[0..-1]
  end
  
  str
end


#begin
  Find.find(path_models) do |path|
    next if File.basename(path)[0,1] == '.' or FileTest.directory?(path) || File.basename(path)[-3,3] != ".rb" 
    entidade = {}
    file = File.open(path).readlines.join
    file = file.gsub(/(^|\n)=begin.*\n=end/, "").gsub(/#.*\n/, "")
    file.gsub!(regex).each do |match|
      atributo, valor = $1.to_sym, $2
      if atributo.to_s =~ /has_many|has_many_with_attributes|has_one|belongs_to/
        # Aqui converte de has_many_with_attributes -para-> has_many
        atributo = :has_many if atributo == :has_many_with_attributes
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

    #Soh entra aqui caso o segundo argumento seja <atributos> 
    if entidade[:super_class] == "ActiveRecord::Base" && ( atributos ) 
      eval <<-EOF
        class Entidade < #{entidade[:super_class]}
          #{"set_table_name :" + entidade[:set_table_name] if entidade[:set_table_name]}
        end
        entidade[:attributes] = Entidade.new.attribute_names
      EOF
    end

    entidade[:usado] = false
    entidades << entidade
    #print "#{entidade.inspect}\n\n"
  end
  
  entidades.uniq!
  entidades.each do |entidade|
    name_space = extrai_name_space entidade[:class], :full
    name_space += '::' unless name_space.empty?
    
    if( atributos )
      yUML << "[#{entidade[:class]}|#{entidade[:attributes] * ";" if entidade[:attributes]}]"
    end
    if not entidade[:super_class].nil? and entidade[:super_class] != "ActiveRecord::Base"
      yUML << "[#{entidade[:class]}]^[#{entidade[:super_class]}]"
    end
    entidade[:has_many] and entidade[:has_many].each do |relacao|
      #yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || relacao[:has_many]}]" #DETECTOR DE CLASSES INATIVA TABAJARA
      # Gambiarra no gsub abaixo! (questao de Inflection)
      yUML << "[#{entidade[:class]}]1-0..*>[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' )).gsub(/ateriai$/, 'aterial' ) }]"                     
        # yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' ))}]"
      entidade[:usado] = true
    end
    entidade[:has_one] and entidade[:has_one].each do |relacao|
      yUML << "[#{entidade[:class]}]1-1>[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' )).gsub(/ateriai$/, 'aterial' ) }]"
        # yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' ))}]"
      entidade[:usado] = true
    end
    
    
    if !entidade[:usado] && sozinhas
      yUML << "[#{ entidade[:class] }]"
    end
  end
  
  yUML.sort!
  
  #IMPRESSAO DO CODIGO
  print yUML.join(", ")
  
  saida = File.new("yUMLmyModels.txt", 'w')
  
  saida.puts"Código gerado automaticamente por yUMLmyModels (#{Time.now - t1}s)"
  saida.puts Time.now().to_s
  saida.puts()
  
  
  old_name_space = ""
  yUML.each{ |y|
    # Separar por NameSpace
    name_space = extrai_name_space(y[1..-1])
    if name_space != old_name_space
      saida.puts ''
      #Mudou de NameSpace, coloca uma nota com o nome donovo namedspace...
      
      saida.puts "[note: #{name_space} {bg:green}]" 
      
      old_name_space = name_space
    end
    
    saida.print y.gsub name_space+'::', ''
    saida.print "," unless yUML.last == y || name_space != old_name_space 
    saida.print "\n"
  }
  saida.close
  puts ""
  puts ""
  puts "Arquivo de saida gerado com sucesso! yUMLmyModels.txt"
  puts "#{yUML.size} models mapeados"
  puts ""
  
  
#rescue Exception => e
#  print "ERRROR: \n#{e}\n"
#end

