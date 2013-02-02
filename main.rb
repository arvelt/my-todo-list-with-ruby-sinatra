require 'sinatra'
require "sinatra/reloader" if development?
require 'Sequel'
require "./models/todo"

get '/' do
  
  #Commentsテーブルから結果セットを取得してビューへ渡す

  @todos = Todo.all
  p "test"
  p @todos
  erb :index
end

post '/add' do
  
  p params[:send_content]
  p params[:send_duedatetime]
    
  #due_dateがtimeなので、空文字いれてしまうとストリングフォーマットしようとして落ちる
  due_date = nil
  if params[:send_duedatetime] != "" then
    due_date = params[:send_duedatetime]
  end
  
  
  #取得したパラメーターを元にtodoモデルを作成
  
  @todo = Todo.new()
  @todo.user_id = "111"
  @todo.status = "1"
  @todo.content = params[:send_content].to_s
  @todo.due_date = due_date
  @todo.save
  
  redirect '/'
end
