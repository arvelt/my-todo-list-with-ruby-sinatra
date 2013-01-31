require 'sinatra'
require "sinatra/reloader" if development?
require 'Sequel'

DB = Sequel.connect('sqlite://todolist-ruby.db')

get '/' do
  
  #Commentsテーブルから結果セットを取得してビューへ渡す
  
  dataset = DB[:todo]

  @todos = dataset.all
  p "test"
  p @todos
  erb :index
end

