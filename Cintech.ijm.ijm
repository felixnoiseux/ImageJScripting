//				Informations
//------------------------------------------------
//
//				  Equipe
//
//	Auteur : Felix Noiseux, Frederic Avoine
//	Date : Automne 2019
//	Projet : Cintech Script d'automatisation de traitement d'image.
//
//				Description		
//				  
//	Ce script permet à un utilisateur de faire le 
//	traitement d'un cube d'images hyperspectral automatiquement.
//	Il est fabriqué à partir d'appel de fonctions.
//	Fonction principale soit choixDefault() si
//	l'utilisateur à sélectionné un cube de 75 images,
//  sinon choixPersonnalise().
//	Ci-dessous : les étapes de fonctionnement.
//
//	1. Ouvre un cube
//	2. Selectionne un bande sur laquelle travaillé
//	3. Defini et applique un Threshold
//	4. Calcul un ZPLOT et eneregistre les données
//
//	 ---Droit de modification permis avec plaisir.---
//
// Note: Les accents sont enlevés des textes pour ne pas avoir de problème d'affichage

opt_default = "Traitement image (.tif) avec 75 bandes";
opt_personnalise = "Traitement image (.tif) personnalise";
nbBandesMax = 75; 
bandeSelectionne = 30; 
myImageID = "";
file = "";

choix = fenetreChoix();
if(choix == opt_default) { choixDefault();}
else if(choix == opt_personnalise){ choixPersonnalise(); }

exit();

//Date : 26 Novembre 2019
//Titre : Fenêtre Principale (Premiere Fenetre)
//Description : Fenêtre apparaissant au lancement du script laissant choix à l'utilisateur.
//				Retourne le choix de l'utilisateur. Soit un cube = 75 bandes ou un cube != 75 bandes.
function fenetreChoix(){

	Dialog.create("Traitement Cube");
	Dialog.addMessage("Veuillez selectionner ce que vous voulez faire.");
	Dialog.addMessage("2 options sont disponibles.");
	Dialog.addChoice("Options :", newArray(opt_default, opt_personnalise));
	Dialog.show();
	
	choix = Dialog.getChoice();
	return choix;
	
}

//Date : 26 Novembre 2019
//Titre : Programme ChoixDefault
//Description : Regrouppe toutes les fonctionnalités du "Script". 
//				C'est ici que le tout ce passe pour un cube de 75 images.
function choixDefault(){
	
	do{
		myImageID = ouvrirCube();
	}
	while(myImageID == 1);
	
	if(nSlices != nbBandesMax){
		afficherErreurBande(); //Mauvais choix
	}
	else {
		bandeSelectionne = selectionnerBand(false); //Demande bande NonPerso 
	    definirThreshold(); //Definit threshold et applique masque
	    ZPlot(); 
	}
	
}

//Date : 26 Novembre 2019
//Titre : Programme ChoixPersonnalisé
//Description : Regrouppe toutes les fonctionnalités du "Script". 
//				C'est ici que le tout ce passe pour un cube autre que 75 images
function choixPersonnalise(){
	
	do{
		myImageID = ouvrirCube(); 
	}
	while(myImageID == 1);
	
	bandeSelectionne = selectionnerBand(true); //Demande bande Perso 
	definirThreshold(); //Definit threshold et applique masque 
	ZPlot(); 
	
}

//Date : 26 Novembre 2019
//Titre : Fonction Permettant d'ouvrir un cube en gérant les exceptions
//Description : Demande à l'utilisateur d'ouvrir un cube. Si le format n'est pas bon, affiche erreur et retourne -1.
//				-1 Sert d'indicateur à la fonction parente.
//
//				do{
//					myImageID = ouvrirCube();
//				}while(myImageID == 1);
//
function ouvrirCube(){

	setBatchMode(true);
	extensions = newArray(".tif",".tiff",".TIFF",".tf2",".tf8",".btf",".ome.tif");
	file = File.openDialog("Choose your stack of images");
	estBonneExtension = false;
	
	//Verifier si l'extension est bonne
	length = lengthOf(file);
	index = lastIndexOf(file, ".");
	extension = substring(file, index, length);

	for(i=0;i<extensions.length;i++){
		if(extensions[i] == extension)
		{
			estBonneExtension = true;
			break;
		}
	}

	if(!estBonneExtension){
		afficherContenu("Type d'extensions autorise : .tif, .tiff, .TIFF, .tf2, .tf8, .btf, .ome.tif" ,"Erreur d'extension");
	}
	else{	
    	run("Bio-Formats", "open=" + file + " autoscale color_mode=Default open_all_series rois_import=[ROI manager] view='Standard ImageJ'stack_order=XYCZT");
    	imageID = getImageID();
		selectImage(imageID);
		return imageID;
	}
	return 1;
	
}


//Date : 30 Octobre 2019
//Titre : Fonction permettant de faire apparaitre un "POP-UP" personnalisé.
//Description : Contenu = Contenu souhaitant afficher, titre = tire de la box
function afficherContenu(contenu,titre){
	Dialog.create(titre);
	Dialog.addMessage(contenu);
	Dialog.show();
}

//Date : 26 Novembre 2019
//Titre : Fonction affichant erreur si la bande n'est pas 75.
//Description : Laisse le choix à l'utilisateur de continuer, en version personnalisée, ou quitter.
function afficherErreurBande(){

	close();
	Dialog.create("Erreur");
	Dialog.addMessage("Ce cube ne contient pas 75 bandes.");	
	Dialog.addChoice("Voulez-vous être redirige vers la version personnalisee  ? \n En repondant : Non vous fermez le programme.", newArray("Oui", "Non"));
	Dialog.show();
	
	choix = Dialog.getChoice();
	if(choix == "Oui"){
		
choixPersonnalise();
	}
	else{
		exit();
	}

}


//Date : 26 Novembre 2019
//Titre : Fonction permettant de selectionner la bande à travailler.
//Description : Si estPersonnalisé, la bande MAX n'est plus 75, mais le max de la personnalisé.
function selectionnerBand(estPersonnalise){

	if(estPersonnalise) {
		nbBandesMax = nSlices;
		diviseur = nbBandesMax % 2;
		bandeSelectionne = (nbBandesMax - diviseur)/2;
	}
	
	
	Dialog.create("Selection bande cube");
	Dialog.addMessage("Selectionner la bande a utiliser dans votre cube.");
	Dialog.addSlider("Bande :", 1, nbBandesMax, bandeSelectionne);
	Dialog.show();
	
	bandeSelectionne = Dialog.getNumber();
	
	//INITIALISATION DE LA BANDE --- A VERIFIER
	for (i=0; i<roiManager("count");i++){
        roiManager("Select", i);
        run("Make Band...", "band=" + bandeSelectionne);
        
	}

	return bandeSelectionne;
}

//Date : 30 Octobre 2019
//Titre : Fonction définissant un Threshold.
//Description : Laisse définir et appliquer le Threshold par l'utilisateur.
function definirThreshold(){

	setBatchMode(false);
	selectImage(myImageID);
	setSlice(bandeSelectionne);
	run("Threshold..."); //Ouvre Threshold                          
	waitForUser("OK, pour appliquer le masque");
	run("Convert to Mask", "method=Mean background=Dark calculate black");                   
	run("Close");
}

//Date : 26 novembre 2019
//Titre : Fonction entourant le diagramme
//Description : Sort les means et stdev
function ZPlot(){
	name = File.nameWithoutExtension;
	dir = File.directory;

	run("Set Measurements...", "mean standard redirect=None decimal=3");
	run("Measure Stack...");

	SaveResult();
}

//Date : 26 novembre 2019
//Titre : Sauvegarde les résultats + le total des means et l'écart-type
//Description : Enregistres les means et stdev dans un fichier txt
function SaveResult()
{
	DebutSelection = 0;
	FinSelection =0;

	if(nSlices == 300)
	{
		DebutSelection = 266;
		FinSelection =275;
	}
	else if(nSlices == 150)
	{
		DebutSelection = 133;
		FinSelection =137;
	}
	else if(nSlices == 75)
	{
		DebutSelection = 66;
		FinSelection =69;
	}

	TotalMean=0;
	TotalStdev =0;

	for (i = DebutSelection; i <= FinSelection; i++) {
		TotalMean += getResult("Mean", i-1);
	}

	TotalStdev =(getResult("StdDev", FinSelection-1) - getResult("StdDev", DebutSelection-1))/2;

	setResult("TotalMean", 0, TotalMean);
	setResult("EcartType", 0, TotalStdev);

	//Enregistre la table de résultat dans un fichier txt du même nom que l'image
	saveAs("Results", dir + name + ".txt");
	run("Close");
	run("Close");

	Ferme la page "log"
	if (isOpen("Log")) { 
         selectWindow("Log"); 
      / run("Close"); 
    } 
}















