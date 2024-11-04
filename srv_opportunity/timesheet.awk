NR == 1 {
    # On traite la ligne d'en-tête (pas de guillemets)
    gsub(";",",",$0);
    print $0
    next
}
{
gsub(",",".",$3);
printf "\"%s\",\"%s\",%s,\"%s\",\"%s\"\n", $1, $2, $3, $4," " 
}
