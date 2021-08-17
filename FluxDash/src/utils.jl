function parse_contents(contents, filename)
  content_type, content_string = split(contents, ',')
  decoded = base64decode(content_string)
  df = DataFrame()
  try
    if occursin("csv", filename)
      str = String(decoded)
      df =  CSV.read(IOBuffer(str), DataFrame)
    end
  catch e
    print(e)
    return html_div([
        "There was an error processing this file."
    ])
  end
   #shuffle data
   n_row = nrow(df)
   shuffle_data = df[shuffle(1:n_row)[:], :]
   shuffle_data[!,"id"] = 1:n_row
  return shuffle_data
end