import pandas as pd
from sqlalchemy import create_engine

conn_string = 'postgresql://postgres:rafe1540@localhost/project_sql'
# connection string : 'postgresql://user(default=postgres):password@host/file_name'

db = create_engine(conn_string)
conn = db.connect()

files = ['artist','canvas_size', 'image_link', 'museum', 'museum_hours', 'product_size', 'subject','work' ]


for file in files:
    df = pd.read_csv(f'C:\\Users\\User\\Downloads\\New folder\\New folder\\{file}.csv')
    df.to_sql(file, con=conn, if_exists='replace',index=False)