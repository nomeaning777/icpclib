# -*- coding:utf-8 -*-
require 'open-uri'
require 'mechanize'

INDEX_URL = "" # メニューページのURL
TARGET_FILE = File.dirname(__FILE__) + "/lib.tex"
WAIT_TIME = 120
RETRY_COUNT = 10
USER = ""
PASSWORD = ""
LOGIN_URL = "http://k8n.biz/wiki/?action=login"

@agent = Mechanize.new
if USER != nil && USER != "" 
  @agent.get('http://k8n.biz/wiki/?action=login')
  @agent.page.form_with(:id => 'loginform') do |form|
    form.field_with(:name => 'name').value = USER
    form.field_with(:name => 'password').value = PASSWORD
    form.click_button
  end
end


def get_url(url)
  retry_count = 0
  res=[]
  url=URI.encode(url)
  begin
    @agent.get(url + '?action=raw').body.force_encoding('UTF-8').each_line do |line|
        res<<=line
    end
  rescue => e
    p e
    if e.to_s.include?("404")
      puts "NotFound:#{url}"
      return []
    end
    retry_count += 1
    if retry_count <= RETRY_COUNT
      puts "Retry!:#{url}"
      sleep WAIT_TIME
      retry
    end
    raise e
  end
  return res
end

$file = File::open(TARGET_FILE, 'w') #, "w:euc-jp")

def texEncode(strc)
  str=strc.dup()
  str.gsub!(/(?<sign>[#_$&\%{}])/,'__ENCODEDYEN__________________\k<sign>')
  str.gsub(/(\|)/, '__ENCODEDBAR__________________')
  str.gsub!(/([<>\\^~])/, '\verb|\0| ')
  str.gsub!('__ENCODEDBAR__________________', '\verb+\0+ ')
  str.gsub!('～','〜')
  return str.gsub('__ENCODEDYEN__________________',"\\")
end

def run(url)
  lines = get_url(url)
  mode = :default
  exit_mode = ""
  lines.each do |line|
    line=line.chomp
    if '## LaTexExit' == line
      break
    end
    if mode == :default
      # タイトル1
      if /^=\s(.+)\s=$/ =~ line
        $file.puts "\\section{#{texEncode($1)}}"
      elsif /^==\s(.+)\s==$/ =~ line
        $file.puts "\\subsection{#{texEncode($1)}}"
      elsif /^===\s(.+)\s===$/ =~ line
        $file.puts "\\subsubsection{#{texEncode($1)}}"
      elsif /{{{#!highlight (.+)$/ =~ line
        highlight = $1
        $file.puts "\\begin{lstlisting}[language=#{highlight}]"
        mode = :highlight
        exit_mode = "}}}"
      elsif /{{{$/ =~ line
        $file.puts "\\begin{lstlisting}[]"
        mode = :highlight
        exit_mode = "}}}"
      elsif /^\|\|(.+)\|\|$/ =~ line
        $file.puts '\begin{table}[h]'
        columns = $1.split('||')
        $file.puts '\begin{tabular}{|' + "l|"*columns.size + '} \hline'
        mode = :table
        redo
      elsif /^\<\<latex\((.+)\)\>\>$/ =~ line
        $file.puts $1
        p $1
      elsif /^ +\*(.+)/ =~ line
        $file.puts '\begin{itemize}'
        puts $1
        mode = :itemize
        redo
      else
        line = "" unless line
        line.gsub!(/!([A-Z][a-z]+[A-Z][a-z]+)/, '\1')
        p texEncode(line)
        $file.puts texEncode(line)
      end
    elsif mode == :highlight
      if line == exit_mode
        $file.puts '\end{lstlisting}'
        mode = :default
      else
        $file.puts line
      end
    elsif mode == :table
      if /^\|\|(.+)\|\|$/ =~ line
        columns = $1.split('||')
        p columns
        start=true
        columns.each do |column|
          if start
            start=false
          else
            $file.print " & "
          end
          $file.print texEncode(column)
        end
        $file.puts(" \\\\ \\hline")
      else
        $file.puts '\end{tabular}'
        $file.puts '\end{table}'
        mode = :default
        redo
      end
    elsif mode == :itemize
      if /^ +\*(.+)/ =~ line
        $file.puts "\\item #{texEncode($1)}"
      else
        $file.puts '\end{itemize}'
        mode=:default
        redo
      end
    end
  end
  if mode == :table
    $file.puts '\end{tabular}'
    $file.puts '\end{table}'
    mode = :default
  end
  if mode == :itemize
    $file.puts '\end{itemize}'
    mode=:default
  end
end

# メニューページを取得する
menu = get_url(INDEX_URL)

menu.each do |line|
  if line.include?("[[")
    match = /\[\[(.+)\|(.+)\]\]/ =~ line
    if match
      target = $1
      run INDEX_URL + target
    end
  end
end

$file.close
