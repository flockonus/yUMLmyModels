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
	
	if File.basename(path)[0,1] != '.' && !FileTest.directory?(path)
		#puts "Estou em:"+path
		#puts "                     SOU RB !!!" 
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

def le_linha(model, path)
	if model.eof?
		$erro.push path
		model.close
		false
	else
		model.readline
	end
end


models_achados.each do |model_path|
	
	#ERRO: if model_path[-19..-1] == "controle_estoque.rb"
	
	model = File.open(model_path, 'r')
	
	puts ''
	puts "  :: Abrindo  :: #{model_path} "
	puts ''
	
	classes_encontradas = 0
	$debug = true

	nome_classe = ""
	nome_tabela = ""
	classes_apontadas = []
	
	
	# Procura o nome da CLASS	(essencial)
#print '0' if $debug	
	next unless linha = le_linha(model, model_path)
	while( !linha.include?( 'class' ) ) do	
		next unless linha = le_linha(model, model_path)
		#puts 'nao... '+linha[1..10]
	end 
	
#print '1' if $debug
	index = linha.index('class')+6
	while( linha[index,1] != " ") do 
		nome_classe += linha[index, 1].to_s
		index +=1
	end
	nome_classe.strip!
	
	
#print '2' if $debug
	#Procura o nome da TABELA	(essencial)
	
	tem_nome_tabela = false
	model_copy = model.clone
	model_copy.rewind
	until( model_copy.eof? ) do
		if model_copy.readline.to_s.include?( 'set_table_name' )
			tem_nome_tabela = true;
			break;
		end
	end
	
	if tem_nome_tabela
		while( !linha.include?( 'set_table_name' ) ) do
			next unless linha = le_linha(model, model_path)
			#puts 'nao... '+linha[1..10]
		end 
	else
			p "Essa tabela nao tem nome!"
	end
	
#print '3' if $debug
	index = linha.index('set_table_name')+16
	while(linha[index,1] != "'" && linha[index,1] != '"' && linha[index,1] != nil ) do 
		nome_tabela += linha[index, 1].to_s
		index +=1
	end
	nome_tabela.strip!


	puts ""+nome_classe+"   (#{nome_tabela}) " if $debug

	#TODO pegar :class_name (se tiver), se nao tiver, devo inferir que eh do mesmo NameSpace?
	#TODO pegar a foreing_key
	puxa_linha = true
	#until(linha.include?('named_s') || linha.include?('validates_') || linha.include?('named_') ) do
	while(linha.strip.index( /^end/).nil? ) do
		next unless linha = le_linha(model, model_path) if puxa_linha
		if(linha.include? "has_many")
			classe_apontada = ""
			index = linha.index('has_many')+10
			while(linha[index,1] != ',' && linha[index,1] != nil  ) do
				classe_apontada += linha[index,1]
				index += 1
			end
			classes_apontadas << classe_apontada
		end
	end
#print '5' if $debug

	#print " >> aponto para: >> "+classe_apontada if $debug
	classes_apontadas.each {|classe_a| puts("    >"+'namespace?::'+ActiveRecord::Base.class_name(classe_a.to_s)+" ") }
	puts "Parei na linha: "+model.lineno.to_s
	puts
	model.close()

end

unless $erro.empty?
	$erros.each do  |e|
		puts "O arquivo #{e} n�o pode ser Parseado corretamente"
	end
end

# = = = = = = = = = = = = = = = = = = = = = = = = =

