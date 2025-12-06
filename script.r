install.packages("data.table")

library(data.table)

catastrophes = fread("./datas/catastrophes.csv")
synop = fread("./datas/synop.csv.gz")

# On filtre le data set des catastrophes pour ne récupérer que les informations pertinentes

# Ici on vire toutes les catastrophes pour lesquelles on ne connait pas l'info précise de sa date de début
# On pourrait potentiellement remplacer les valeurs absentes ?? Par exemple si il manque le jour, mettre le 1 du mois ?
catastrophes_dates_remplies = catastrophes[!is.na(start_month) & !is.na(start_year)]

# Ici on garde que les catastrophes françaises
catastrophes_francaises = catastrophes_dates_remplies[country == "France"]

# On affiche les tailles des datasets, on voit bien que les filtres font leurs effets
nrow(catastrophes)
nrow(catastrophes_dates_remplies)
nrow(catastrophes_francaises)

# On renomme la colonne des températures pour préciser que c'est des Kelvin ici pour y voir plus clair
setnames(synop, old = "t", new = "t_kelvin")

# On crée une colonne pour avoir les températures en C° dès le départ
synop[, "t_celsius"] = synop[, t_kelvin - 273.15]
synop

# Tronche du dataset final
result = data.table(
  year = integer(),
  month = integer(),
  avg_temp = numeric(),
  temp_gap = numeric(),
  total_disasters = integer(),
  total_damages = numeric(),
  total_deaths = integer()
)


