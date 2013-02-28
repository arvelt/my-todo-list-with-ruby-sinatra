# coding: utf-8
require 'sinatra/base'
require 'sequel'
require "omniauth"
require "omniauth-google-oauth2"
require "./models/todo"
require 'slim'
require "sinatra/reloader"

class Main < Sinatra::Base

  
  Slim::Engine.default_options[:pretty] = true  #出力htmlを整形する設定  true=>する,false=>しない
  
  #環境設定
  set :environment, :development
  
  #urlrootの場所を固定持ちさせる
  configure :development do
    @@env = :dev
    @@root = ''
  end
  configure :production do
    @@env = :pro
    @@root = '/todolist/'
  end
  configure :production do
    @@env = :test
  end
  
  # Sinatra のセッションを有効にする-
  enable :sessions
    
  # OmniAuth の設定
  use OmniAuth::Builder do
    provider :google_oauth2, ENV['GOOGLE_ID'], ENV['GOOGLE_SECRET']
  end
  
  # 開発環境の場合はテストモックを使用
  configure :development , :test do
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
    p request.env["omniauth.auth"]
    @oauth = request.env["omniauth.auth"]
    session[:oauth] = @oauth
    session[:user_id] = @oauth['uid']
    session[:name] = @oauth['info']['email']
    session[:logined] = true
    @logined = true
    p "logined:#{@logined}"
    p "env:#{@@env}"
      
    #この位置でundefined method `configure'といわれるので、自前で振り分けることにする
    if @@env == :dev
      redirect '/'
    elsif @@env == :pro
      redirect @@root 
    elsif @@env == :test
      redirect '/'
    end
  end
  
  get '/logout' do
    session.clear
    if @@env == :dev
      redirect '/'
    elsif @@env == :pro
      redirect @@root 
    elsif @@env == :test
      redirect '/'
    end
  end
  
  get '/' do
    @root = @@root
      
    puts "path_info:#{request.path_info}"
    
    #セッション値を取得
    @logined = session[:logined]
    @name = session[:name]
  
    #------------------------------------------
    #　Session[user_id]に有効なIDする設定する
    #   →セッションIDか、auth認証したIDのどちらかが入っている
    #------------------------------------------
    user_id = get_userid_from_session( session )
    puts "user_id:#{user_id}"
    
    #Commentsテーブルから結果セットを取得してビューへ渡す
    @todos = Todo.where(:user_id=>user_id).all
    puts "show todos:#{@todos}"
    slim :index
  end
  
  post '/add' do
    @root = @@root
    
    puts "path_info:#{request.path_info}"  
    puts "params:#{params}"
  
    #ユーザーIDを取得
    user_id = get_userid_from_session( session )
    puts "user_id:#{user_id}"
    
    due_date = params[:send_duedatetime]
  
    #入力をチェック  
    @err = check_format_duedate( due_date )
    p "err:#{@err}"
          
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
    puts "show todos:#{@todos}"
    slim :_list
  end
  
  post '/delete' do
    @root = @@root
   
    puts "path_info:#{request.path_info}"  
    puts "params:#{params}"

    key = params[:key]
    user_id = session[:user_id]
      
    #ユーザーIDを取得
    user_id = get_userid_from_session( session )
    puts "user_id:#{user_id}"
    
    #取得したパラメーターを元にtodoモデルを削除
    @todo = Todo[:id=>key]
    @todo.destroy
    
    #自分のtodoを取得して返す
    @todos = Todo.where(:user_id=>user_id).all
    slim :_list
  end
  
  post '/update' do
    @root = @@root
  
    puts "path_info:#{request.path_info}"  
    puts "params:#{params}"
  
    #パラメタ取得
    key =  params[:key]
    status =  params[:status]
    content = params[:content]
    due_date = params[:due_date]
    user_id = session[:user_id]
  
    #ユーザーIDを取得
    user_id = get_userid_from_session( session )
    puts "user_id:#{user_id}"
  
    #入力をチェック  
    @err = check_format_duedate( due_date )
    p "err:#{@err}"
    
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
  

  # 日付のフォーマットチェック
  def check_format_duedate( due_date )
  
    #due_dateがtimeなので、空文字いれてしまうとストリングフォーマットしようとして落ちる
  
    return nil if due_date.nil?
    
    if due_date == "" then
      due_date = nil
    else
      
      #入力があればフォーマットチェック
      begin
        Date.strptime(due_date, "%Y-%m-%d %H:%M")
      rescue 
        return "その日時を指定することはできません"
      end
    end
    
    return nil
  end

  #　session[user_id]、session[session_id]のうち、
  #　有効なものを返却する
  def get_userid_from_session ( session )

    if session[:user_id].nil? 
      session[:user_id] =  session[:session_id]
      return session[:session_id]
    else
      return session[:user_id] 
    end  
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
  