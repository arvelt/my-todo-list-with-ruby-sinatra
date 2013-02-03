require 'sinatra'
require "sinatra/reloader" if development?
require 'Sequel'
require "./models/todo"
require 'slim'
Slim::Engine.default_options[:pretty] = true  #出力htmlを整形する設定  true=>する,false=>しない

get '/' do
  
  #Commentsテーブルから結果セットを取得してビューへ渡す

  @todos = Todo.all
  p "test"
  p @todos
  slim :index
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
  
  #全てのtodoを取得して返す
  @todos = Todo.all
  slim :list
end

post '/delete' do
  
  p params[:key]
  key = params[:key]
    
  #取得したパラメーターを元にtodoモデルを作成
  @todo = Todo[:id=>key]
  @todo.destroy
  
  #全てのtodoを取得して返す
  @todos = Todo.all
  slim :list
end

post '/update' do
  
  p params[:key]
  p params[:status]
  p params[:content]
  p params[:due_date]

  #パラメタ取得
  key =  params[:key]
  status =  params[:status]
  content = params[:content]
  due_date = params[:due_date]
    
  #主キーでモデルを取得し、更新して保存
  @todo = Todo[:id=>key]
  @todo.update(
    :status => status,
    :content => content,
    :due_date => nil
  )
  @todo.save
  
  #全てのtodoを取得して返す
  @todos = Todo.all
  slim :list
end