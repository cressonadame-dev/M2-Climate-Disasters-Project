# Usage de l'IA (ChatGPT, Perplexity, Gemini) :
# - Relecture et aide sur le code
# - Suggestions pour la structure des graphiques
# - Aide à l'interprétation des résultats des régressions



library(data.table)

catastrophes = fread("./datas/catastrophes.csv")

# Renommage des colonnes pour plus de clarté
setnames(catastrophes, old = "start_month", new = "month")
setnames(catastrophes, old = "start_year", new = "year")

# Les nombres de morts en NA passent à 0 (on pourrait normaliser tout ça au besoin ???)
catastrophes$total_deaths[is.na(catastrophes$total_deaths)] <- 0

# Idem pour les dégats en $
# total_damages_adjusted_thousand_usd existe aussi dans les catas !!!
catastrophes$total_damages_thousand_usd[is.na(catastrophes$total_damages_thousand_usd)] <- 0

# On filtre le data set des catastrophes pour ne récupérer que les informations pertinentes

# Ici on vire toutes les catastrophes pour lesquelles on ne connait pas l'info précise de sa date de début
# On pourrait potentiellement remplacer les valeurs absentes ?? Par exemple si il manque le jour, mettre le 1 du mois ?
catastrophes_dates_remplies = catastrophes[!is.na(month) & !is.na(year)]

# Ici on garde que les catastrophes françaises
catastrophes_francaises = catastrophes_dates_remplies[country == "France"]

# On affiche les tailles des datasets, on voit bien que les filtres font leurs effets
nrow(catastrophes)
nrow(catastrophes_dates_remplies)
nrow(catastrophes_francaises)

# Affichage des catastrophes naturelles apparues en juin 2013
catastrophes_francaises[month == 6 & year == 2013]

# On commence à construire le dataset de sortie
# Ici on group by par mois et année et pour chaque clé on calcule la moyenne des
# morts, la moyenne des dégats en dollars et le nombre de désastres
res = catastrophes_francaises[, list(morts_moyen = mean(total_deaths), dommages_dollars = mean(total_damages_thousand_usd) * 1000, nb_desastres = .N), by = list(month, year)]
res

synop = fread("./datas/synop.csv.gz")

# Gestion des NA : on les vire
synop = synop[!is.na(synop$t)] 

# On renomme la colonne des températures pour préciser que c'est des Kelvin ici pour y voir plus clair
setnames(synop, old = "t", new = "t_kelvin")

# On crée une colonne pour avoir les températures en C° dès le départ
synop[, "t_celsius"] = synop[, t_kelvin - 273.15]
synop

# Ici on group by par mois et année et pour chaque clé on calcule la moyenne des t C°
temperatures_mois = synop[, list(temperature_moyenne = mean(t_celsius)), by = list(month, year)]
temperatures_mois

# Ici on calcule la moyenne des températures de chaque mois
temperatures_mois_moyenne = temperatures_mois[, list(temperature_mois_moyenne = mean(temperature_moyenne)), by = list(month)]
temperatures_mois_moyenne

# On joint les deux datasets pour avoir la différence entre la température moyenne du mois et la température moyenne globale de ce mois
temperatures_mois[temperatures_mois_moyenne, on = "month", 
                  diff_moyenne_mois := temperature_moyenne - temperature_mois_moyenne]

# On arrondit les températures à 2 chiffres apprès la virgule
temperatures_mois$temperature_moyenne = round(x = temperatures_mois$temperature_moyenne, digits= 2)


# On join l'analyse du dataset de météo france avec celle des catastrophes
res = res[temperatures_mois, on = list(month, year)]

# Types + index de temps mensuel
res[, month := as.integer(month)]
res[, year  := as.integer(year)]
res[, date  := as.IDate(sprintf("%04d-%02d-01", year, month))]

# Transformations (stabiliser les variables très asymétriques)
res[, ln_dommages := log1p(dommages_dollars)]
res[, ln_morts    := log1p(morts_moyen)]

# Filtre minimal
res <- res[!is.na(temperature_moyenne) & !is.na(nb_desastres)]

# Labels mois (pour graphes de saisonnalité)
res[, month_lab := factor(month, levels = 1:12, labels = month.abb)]

res

if (!dir.exists("output")) {
  dir.create("output")
}

fwrite(res, "./output/result.csv", scipen = 999)