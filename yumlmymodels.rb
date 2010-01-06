require 'find'
require 'rubygems'
require 'active_record' rescue require 'activerecord'
#gem 'activesupport'
#  require 'inflector_portuguese.rb'
require 'yaml'


$t1 = Time.now

path_rails = $*[0] rescue "."

atributos, sozinhas, belongs = false
ARGV[1,12].each do |arg|
  case arg
    when 'atributos' then
      atributos = true;
    when 'sozinhas' then
      sozinhas = true;
    when 'belongs' then
      belongs = true;
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

class String
  def to_class_name
    ActiveRecord::Base.class_name(self.gsub(/ornecedores$/, 'ornecedor' )).gsub(/ateriai$/, 'aterial' )
  end
end

def extrai_name_space(str, qualidade = :first)
    
  if str.include?(':')
    if qualidade == :full
      str = str[0..str.rindex(':') -2] rescue ""
    elsif qualidade == :first
      str = str[0..str.index(':') -1] rescue ""
    end
  else
    str = str[0..-1]
  end
  
  str
end

def unico!
  ($t1 - Time.now).to_s.gsub('.','').gsub('-','')
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

    #Soh entra aqui caso tenha o argumento <atributos> 
    if entidade[:super_class] == "ActiveRecord::Base" && ( atributos )
      
      diferencial = unico!
      eval <<-EOF
        class Entidade#{diferencial} < #{entidade[:super_class]}
          #{"set_table_name :" + entidade[:set_table_name] if entidade[:set_table_name]}  rescue puts("   !"+entidade[:class])
        end
        entidade[:attributes] = Entidade#{diferencial}.new.attribute_names rescue puts("   !"+entidade[:class])
      EOF
      
      #if entidade[:class] == 'Expedicao::AssistenciaProduto'
      #end
      
    end

    entidade[:usado] = false
    entidades << entidade
    #print "#{entidade.inspect}\n\n"
  end
  
  entidades.uniq!
  entidades.each do |entidade|
    name_space = extrai_name_space entidade[:class], :full
    name_space += '::' unless name_space.empty?
    
    # ATRIBUTOS
    if( atributos )
      yUML << "[#{entidade[:class]}|#{entidade[:attributes] * ";" if entidade[:attributes]}]"
    end
    
    # HERANCA
    if not entidade[:super_class].nil? and entidade[:super_class] != "ActiveRecord::Base"
      yUML << "[#{entidade[:class]}]^[#{entidade[:super_class]}]"
    end
    
    # HAS_MANY
    entidade[:has_many] and entidade[:has_many].each do |relacao|
      #yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || relacao[:has_many]}]" #DETECTOR DE CLASSES INATIVA TABAJARA
      # Gambiarra no gsub abaixo! (questao de Inflection)
      yUML << "[#{entidade[:class]}]1-0..*>[#{relacao[:class_name] || name_space + relacao[:has_many].to_class_name }]"                     
        # yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' ))}]"
      entidade[:usado] = true
    end
    
    # HAS_ONE
    entidade[:has_one] and entidade[:has_one].each do |relacao|
#puts relacao.inspect
      yUML << "[#{entidade[:class]}]1-1>[#{relacao[:class_name] || name_space + relacao[:has_one].to_class_name }]"
        # yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' ))}]"
      entidade[:usado] = true
    end
    
    # BELONGS_TO
    ( entidade[:belongs_to] && belongs) and entidade[:belongs_to].each do |relacao|
      if( relacao[:class_name] )
        yUML << "[#{ entidade[:class] }]B->[#{ relacao[:class_name] || name_space + relacao[:class_name].to_class_name }]"
          # yUML << "[#{entidade[:class]}]1-0..*[#{relacao[:class_name] || name_space + ActiveRecord::Base.class_name(relacao[:has_many].gsub(/ornecedores$/, 'ornecedor' ))}]"
        entidade[:usado] = true
      end
    end
    
    # CLASSES SEM RELACOES
    if !entidade[:usado] && sozinhas
      yUML << "[#{ entidade[:class] }]"
    end
  end
  
  
  
  
  #entidades.each { |e|    puts e.inspect  }
  
  yUML.sort!
  
  
  
  
  
  #IMPRESSAO DO CODIGO
  #print yUML.join(", ")
  
  puts ""
  puts "Argumentos: #{ARGV.join(", ")}"
  
  saida = File.new("yUMLmyModels.txt", 'w')
  
  saida.puts "Código gerado automaticamente por yUMLmyModels (#{Time.now - $t1}s)"
  saida.puts "Argumentos: #{ARGV.join(", ")}"
  saida.puts Time.now().to_s
  saida.puts()
  
  
  old_name_space = ""
  yUML.each{ |y|
    # Separar por NameSpace
    name_space = extrai_name_space(y[1..-1])
    if name_space != old_name_space
      saida.puts ''
      #Mudou de NameSpace, coloca uma nota com o nome do novo namespace...
      saida.puts "[note: #{name_space} {bg:green}]" 
    end
    
    saida.print y.gsub( name_space+'::', '')
    saida.print "," unless yUML.last == y
    saida.print "\n"
    old_name_space = name_space if name_space != old_name_space
  }
  saida.close
  puts ""
  puts "Arquivo de saida gerado com sucesso! yUMLmyModels.txt"
  puts "#{yUML.size} models mapeados (#{Time.now - $t1}s)"
  puts ""
  
  
#rescue Exception => e
#  print "ERRROR: \n#{e}\n"
#end

