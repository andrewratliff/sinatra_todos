require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"

if development?
  require "pry"
  require "sinatra/reloader"
end

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, escape_html: true
end

helpers do
  def completed?(list)
    !list[:todos].empty? && list[:todos].all? { |todo| todo[:completed] }
  end

  def list_progress(list)
    completed = list[:todos].reject { |todo| todo[:completed] }.count
    total = list[:todos].count

    "#{completed} / #{total}"
  end

  def list_class(list)
    completed?(list) ? "complete" : ""
  end

  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition { |list| completed?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
  end
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

get "/lists/:list_id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  @todos = @list[:todos]

  erb :list
end

get "/lists/:list_id/edit" do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]

  erb :edit_list
end

post "/lists/:list_id/edit" do
  list_id = params[:list_id].to_i
  list_name = params[:list_name].strip
  @list = load_list(@list_id)

  if invalid_list_name?(list_name)
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{list_id}"
  end
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  if invalid_todo_name?(text)
    erb :list
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/delete" do
  load_list(params[:list_id])
  session[:lists].delete_at(params[:list_id].to_i)
  session[:success] = "The list has been deleted successfully."
  redirect "/lists"
end

post "/lists/:list_id/complete" do
  list_id = params[:list_id].to_i
  list = load_list(list_id)
  list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "The list has been completed."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/todos/:todo_id/delete" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = load_list(list_id)
  list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted successfully."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/todos/:todo_id" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = load_list(list_id)
  completed = params[:completed] == "true"
  list[:todos][todo_id][:completed] = completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{list_id}"
end

private

def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

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
