#FIX me - Fabiano P Soriani

#FIX Objetivo: Fazer o parse de todas as classes de model em Rails, e descobrir todos has_many de cada classe, para poder desenhar.
#	Não tem o objetivo de validar as relacoes, só parsear e tradur em sintaxe http://yuml.me/diagram/scruffy/class/draw

require 'find'
require 'fileutils'

# tudo isso para usar o methodo: ActiveRecord::Base.class_name(str)
	require 'rubygems'
	require 'active_record'
#/ tudo isso para usar o methodo: ActiveRecord::Base.class_name(str)

models_achados = []
puts "Estou em:"+Dir::pwd()
Find.find('./app/models') do |path|
	
  # Coleta todos os .rb de models
	if File.basename(path)[0,1] != '.' && !FileTest.directory?(path)
		models_achados << path
	end
end
puts
puts "Achei #{models_achados.size} .rb !"
models_achados.each{ |model_path|
	puts("    "+model_path)
	#model = File.open(model_path, 'r')
	#puts "        "+model.readlines[1][0..10]+'(...)'
}
puts 

$erro = []
$falhas = []

#Funcao recursiva que soh para quando acha uma linha valida ou EOF, nunca setar seek_end de fora!
def le_linha(model, path, seek_end = false)
	# Ops.... acabou o arquivo <antes do esperado?>
  if model.eof?
    $erro.push path
    model.close
    false
  #Consegui uma linha ok, aprofunda ate ser valida!
  else
		l = model.readline
    
    # IF para o caso da linha ser um comentario inline (#)!
    if l.lstrip[0,1] == '#'
      return le_linha(model, path)
    end

    # IF para o caso da linha ser um comentario de bloco (=begin)
    if l[0,6] == '=begin'
      return le_linha(model, path, true) #busca ate achar o =end
    end
    
    # esse IF denota que esta dentro de linha de comentario 
    if seek_end == true
      if l[0,4] == '=end'
        return le_linha(model, path, false)
      else
        return le_linha(model, path, true)
      end
    end
    
    # Se passou tudo acima eh uma linha valida! 
    return l
    
	end
end


#Watch n Learn the power of eval! =D
def has_many(classe, *args)
  puts "minha classe: #{classe.to_s}"
  puts "minhas entranhas: #{args.inspect}"
end












models_achados.each do |model_path|
  
  if model_path[-19..-1] == "controle_estoque.rb"
	 sleep 0
  end
  
  
	model = File.open model_path, 'r' 
	
	puts ''
	puts "  :: Abrindo  :: #{model_path} "
	puts ''
	
	classes_encontradas = 0
	$debug = true

	nome_classe = ""
	nome_tabela = ""
	classes_apontadas = []
	
	
	# Procura o nome da CLASS	(essencial)
	next unless linha = le_linha(model, model_path)
	while( !linha.include?( 'class' ) ) do	
		next unless linha = le_linha(model, model_path)
		#puts 'nao... '+linha[1..10]
	end 
	
	index = linha.index('class')+6
	until( linha[index,1] == " " || linha[index,1].empty? ) do 
		nome_classe += linha[index, 1].to_s
		index +=1
	end
	nome_classe.strip!
	
	
	#Procura o nome da TABELA	(essencial)
	model2 = File.open model_path, 'r'
	until( model2.eof? ) do
   line = model2.readline 
		if line.include?( 'set_table_name' )
      #PARSE a <line> e extrai o nome da tabela por expressao reg
      line.gsub! 'set_table_name', ''
      line.gsub! "'", ""
      line.gsub! '"', ''
      line.gsub! ':', ''
      nome_tabela = line.strip
      sleep 0
      next unless linha = le_linha(model, model_path)
			break;
		end
  end
  model2.close()
  
	puts ""+nome_classe+"   (#{nome_tabela}) " if $debug
  
	#TODO pegar :class_name (se tiver), se nao tiver, devo inferir que eh do mesmo NameSpace?
	#TODO FUTURO pegar a foreing_key
	puxa_linha = true
	# Procurar HAS_MANY's ateh achar uma linha comecando por END 
	while(linha.strip.index( /^end/).nil? ) do
		next unless( linha = le_linha(model, model_path) if(puxa_linha))
    
		if(linha.include? "has_many")
      # Remove o \n e os comentarios de linha
      linha = linha[0..-2].match(/([^#]*)/).to_s
      while linha.rstrip[-1,1] == ','
        linha += le_linha(model, model_path).match(/([^#]*)/).to_s
      end
      puts(">>>>>>> vou eval: #{linha}")
      
      
=begin
    #  CASO + CABELUDO (imaginado ateh agora): 
  has_many :conversacaos_clientes, :foreign_key => :pessoa_id, # adasdasdad
    :class_name => "Comercial::Conversacoes", :dependent => :destroy
=end
			#RECONTRUIR O PARSE AQUI A PARTIR DA MINHA FUNC has_many ;)
      #classe_apontada = ""
			#index = linha.index('has_many')+10
			#while(linha[index,1] != ',' && linha[index,1] != nil  ) do
			#	classe_apontada += linha[index,1]
			#	index += 1
			#end
			#classes_apontadas << classe_apontada
		end
	end

	#print " >> aponto para: >> "+classe_apontada if $debug
	classes_apontadas.each {|classe_a| puts("    >"+'namespace?::'+ActiveRecord::Base.class_name(classe_a.to_s)+" ") }
	puts "Parei na linha: "+model.lineno.to_s
	puts
	model.close()

end

unless $erro.empty?
	$erros.each do  |e|
		puts "O arquivo #{e} nao pode ser Parseado corretamente"
	end
end

# = = = = = = = = = = = = = = = = = = = = = = = = =

