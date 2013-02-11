# coding: utf-8
require 'sinatra'
require "sinatra/reloader" if development?
require 'sequel'
require "omniauth"
require "omniauth-google-oauth2"
require "./models/todo"
require 'slim'
Slim::Engine.default_options[:pretty] = true  #出力htmlを整形する設定  true=>する,false=>しない

#環境設定
set :environment, :production
#set :environment, :development

#静的ファイルの場所を固定持ちさせる
configure :development do
  @@root = ''
end
configure :production do
  @@root = '/todolist/'
end

# Sinatra のセッションを有効にする-
enable :sessions
  
# OmniAuth の設定
use OmniAuth::Builder do
  # Twitter の OAuth を使う
  provider :google_oauth2, ENV['GOOGLE_ID'], ENV['GOOGLE_SECRET']
end

# 開発環境の場合はテストモックを使用
configure :development do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = {
    "provider" => "google",
    "uid" => 4580841,
    "info" => {
      "name" => "Arvelt S",
      "email" => "arvelt.s-aaaaaaaa@gmail.com",
    },
  }
end

get "/auth/:provider/callback" do
  @root = @@root

  # 認証情報は request.env に格納されている
  # uidとnameをセッションに入れて使う
  
  #raise request.env["omniauth.auth"]
  @oauth = request.env["omniauth.auth"]
  session[:oauth] = @oauth
  session[:logined] = true
  session[:user_id] = @oauth['uid']
#  session[:name] = @oauth['info']['name']
  session[:name] = @oauth['info']['email']
  @logined = session[:logined]
  p @logined
    
#  @todos = Todo.all
#  slim :index
  configure :development do
    redirect '/'
  end
  configure :production do
    redirect @@root
  end
end

get '/logout' do
  session.clear
  configure :development do
    redirect '/'
  end
  configure :production do
    redirect @@root
  end
end

get '/' do
  @root = @@root
    
  p session[:user_id]
  p session[:session_id]
  
  #セッション値を取得
  @logined = session[:logined]
  @name = session[:name]
  user_id = session[:user_id]
  p @logined

  #------------------------------------------
  #　Session[user_id]に有効なIDする設定する
  #   →セッションIDか、auth認証したIDのどちらかが入っている
  #------------------------------------------
  user_id = ""
  @name = session[:name] unless session[:name]
  if session[:user_id].nil? 
    user_id = session[:session_id]
    session[:user_id] =  session[:session_id]
  else
    user_id = session[:user_id] 
    @name = session[:name]
  end
  p user_id

  
  #Commentsテーブルから結果セットを取得してビューへ渡す
  p request.path_info
  @todos = Todo.where(:user_id=>user_id).all
  p "test"
  p @todos
  slim :index
end

post '/add' do
  @root = @@root
  
  p session[:user_id]
  p session[:session_id]

  p params[:send_content]
  p params[:send_duedatetime]

  @logined = session[:logined]
  p @logine
    
  user_id = session[:user_id]
  @name = session[:name] unless session[:name]
  
  due_date = params[:send_duedatetime]
  
  @err = nil

  #due_dateがtimeなので、空文字いれてしまうとストリングフォーマットしようとして落ちる
  if due_date == "" then
    due_date = nil
  else
    
    #入力があればフォーマットチェック
    begin
      Date.strptime(due_date, "%Y-%m-%d %H:%M")
    rescue 
      @err = "その日時を指定することはできません"
    end
  end
    
  if @err.nil?
    #取得したパラメーターを元にtodoモデルを作成
    @todo = Todo.new()
    @todo.user_id = user_id
    @todo.status = "1"
    @todo.content = params[:send_content].to_s
    @todo.due_date = due_date
    @todo.save
  end
  
  #自分のtodoを取得して返す
  @todos = Todo.where(:user_id=>user_id).all
  slim :_list
end

post '/delete' do
  @root = @@root
 
  key = params[:key]
  user_id = session[:user_id]
  p key
  p user_id
    
  user_id = session[:user_id]
  @name = session[:name] unless session[:name]
  p user_id

  
  #取得したパラメーターを元にtodoモデルを作成
  @todo = Todo[:id=>key]
  @todo.destroy
  
  #自分のtodoを取得して返す
  @todos = Todo.where(:user_id=>user_id).all
  slim :_list
end

post '/update' do
  @root = @@root

  p params[:key]
  p params[:status]
  p params[:content]
  p params[:due_date]

  #パラメタ取得
  key =  params[:key]
  status =  params[:status]
  content = params[:content]
  due_date = params[:due_date]
  user_id = session[:user_id]

  user_id = session[:user_id]
  @name = session[:name] unless session[:name]

  @err = nil

  #due_dateがtimeなので、空文字いれてしまうとストリングフォーマットしようとして落ちる
  if due_date == "" then
    due_date = nil
  else
    
    #入力があればフォーマットチェック
    begin
      Date.strptime(due_date, "%Y-%m-%d %H:%M")
    rescue 
      @err = "その日時を指定することはできません"
    end
  end
    
  p @err
  
  if @err.nil?
    #主キーでモデルを取得し、更新して保存
    @todo = Todo[:id=>key]
    @todo.update(
      :status => status,
      :content => content,
      :due_date => due_date
    )
    @todo.save
  end
    
  
  #自分のtodoを取得して返す
  @todos = Todo.where(:user_id=>user_id).all
  slim :_list
end