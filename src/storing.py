import pandas as pd
from sqlalchemy import create_engine

#static data retrieval for building the model
#the path is local, since the data is private and only a subset will be uploaded on GitLab
data = pd.read_csv("C:/Users/Usuari/Desktop/svv_data.csv", encoding = "UTF-8", error_bad_lines=False, 
                sep=';', low_memory=False)
data.head(10)

#DB connection
#xxxxxxxxxx - encoded pw (just to show the method for reproducibility)
try:
    con = create_engine('postgresql://######:xxxxxxxxx@#############:####/db')
except:
    print("Wrong DB connection!")

#writing df to db table
data.to_sql('raw_data_svv', con)

#check if table has been uploaded
print (con.table_names())
