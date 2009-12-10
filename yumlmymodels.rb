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
=begin
		if FileTest.directory?(path)
			next
		else
			#do stuff FileUtils.remove_dir(path, true)
			dir = Dir.new(Dir::pwd()+path[1..-1])
			models_da_pasta = dir.entries().select{ |file| file[-3,3] == '.rb' }
			#models_da_pasta.collect! {|file| Dir::pwd()+'/app/model/'+file }
			models_da_pasta.collect! {|file| path+'/'+file }

			modelos_achados += models_da_pasta
		end
=end
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




models_achados.each do |model_path|


	model = File.open(model_path)

	classes_encontradas = 0
	$debug = true

	nome_classe = ""
	nome_tabela = ""
	classes_apontadas = []






	# Procura o nome da CLASS	(essencial)
	linha = model.readline
	while( !linha.include?( 'class' ) ) do	
		linha = model.readline
		#puts 'nao... '+linha[1..10]
	end 
	index = linha.index('class')+6
	while( linha[index,1] != " ") do 
		nome_classe += linha[index, 1].to_s
		index +=1
	end

	#Procura o nome da TABELA	(essencial)
	while( !linha.include?( 'set_table_name' ) ) do
		linha = model.readline
		#puts 'nao... '+linha[1..10]
	end 
	index = linha.index('set_table_name')+16
	while(linha[index,1] != "'" && linha[index,1] != '"' && linha[index,1] != nil ) do 
		nome_tabela += linha[index, 1].to_s
		index +=1
	end


	puts 
	puts "  :: EXEMPLO  ::  "
	puts ""+nome_classe+"   (#{nome_tabela})" if $debug


	#TODO pegar :class_name (se tiver), se não tiver, devo inferir que é do mesmo NameSpace?
	#TODO pegar a foreing_key
	puxa_linha = true
	#until(linha.include?('end')) do
	until(linha.include?('named_s') || linha.include?('validates_') || linha.include?('named_') ) do
		linha = model.readline if puxa_linha
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

	#print " >> aponto para: >> "+classe_apontada if $debug
	classes_apontadas.each {|classe_a| puts("    >"+'namespace?::'+ActiveRecord::Base.class_name(classe_a.to_s)+" ") }
	puts
	puts "Parei na linha: "+model.lineno.to_s
	puts
end

# = = = = = = = = = = = = = = = = = = = = = = = = =

