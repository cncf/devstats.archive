def mgetc
  return ENV['GHA2DB_MGETC'] if ENV['GHA2DB_MGETC']
  begin
    system 'stty raw -echo'
    str = STDIN.getc
  ensure
    system 'stty -raw echo'
  end
  str.chr
end
