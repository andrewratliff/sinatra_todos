require "sinatra"
require "sinatra/content_for"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"

configure do
  enable :sessions
  set :session_secret, "secret"
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists
end

post "/lists/new" do
  list_name = params[:list_name].strip
  if invalid_list_name?(list_name)
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/new" do
  erb :new_list
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @todos = @list[:todos]

  erb :list
end

get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list
end

post "/lists/:id/edit" do
  id = params[:id].to_i
  list_name = params[:list_name].strip
  @list = session[:lists][id]

  if invalid_list_name?(list_name)
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  if invalid_todo_name?(text)
    erb :list
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:id/delete" do
  session[:lists].delete_at(params[:id].to_i)
  session[:success] = "The list has been deleted successfully."
  redirect "/lists"
end

post "/lists/:id/complete" do
  list_id = params[:id].to_i
  list = session[:lists][list_id]
  list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "The list has been completed."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/todos/:todo_id/delete" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  session[:lists][list_id][:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted successfully."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/todos/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  completed = params[:completed] == "true"
  session[:lists][list_id][:todos][todo_id][:completed] = completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{list_id}"
end

private

def invalid_list_name?(list_name)
  error = false

  if !(1..100).cover?(list_name.length)
    session[:error] = "The list name must be between 1 and 100 characters."
    error = true
  elsif session[:lists].any? { |list| list[:name] == list_name }
    session[:error] = "The list name must be unique."
    error = true
  end

  error
end

def invalid_todo_name?(todo)
  error = false

  if !(1..100).cover?(todo.length)
    session[:error] = "The todo must be between 1 and 100 characters."
    error = true
  end

  error
end
