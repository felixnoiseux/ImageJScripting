//TODO : ETAPE 2.

nbBandesMax = 75; //Corespond au nombre de longeur d'onde utilise par default
bandeSelectionne = 30; //30 par default
myImageID = "";
file = "";
opt_default = "Traitement image (.tif) avec 75 bandes";
opt_personnalise = "Traitement image (.tif) personnalise";

//DEBUT
Dialog.create("Traitement Cube");
Dialog.addMessage("Veuillez sélecitonner ce que vous voulez faire.");
Dialog.addMessage("2 options est disponible.");
Dialog.addChoice("Options :", newArray(opt_default, opt_personnalise));
Dialog.show();
choix = Dialog.getChoice();

if(choix == opt_default)
{
	myImageID = ouvrirCube();
	if(nSlices != nbBandesMax){
		afficherErreur(); //Mauvais choix
	}
	else {
		bandeSelectionne = selectionnerBand(false); //Demande bande NonPerso
	    definirThreshold();//Defini threshold et applique masque
	}
}
else if(choix == opt_personnalise){
	myImageID = ouvrirCube();
	bandeSelectionne = selectionnerBand(true); //Demande bande Perso
	definirThreshold(); //Defini threshold et applique masque
}

exit();
//FIN


//FONCTIONS CREE
function ouvrirCube(){
	setBatchMode(true);
	file = File.openDialog("Choose your stack of images");
    run("Bio-Formats", "open=" + file + " autoscale color_mode=Default open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
    imageID = getImageID();
	selectImage(imageID);
	return imageID;
}
function afficherErreur(){
	close();
	Dialog.create("Erreur");
	Dialog.addMessage("Cube ne contient pas 75 bandes. Veuillez recommencer.");	
	Dialog.show()
	exit();

}
function selectionnerBand(estPersonnalise){

	if(estPersonnalise == true) {
		nbBandesMax = nSlices;
		diviseur = nbBandesMax % 2;
		bandeSelectionne = (nbBandesMax - diviseur)/2;
	}
	
	//close();
	Dialog.create("Selection bande cube");
	Dialog.addMessage("Selectionner la bande a travaille sur votre cube.");
	Dialog.addSlider("Bande :", 0, nbBandesMax, bandeSelectionne);
	Dialog.show();
	bandeSelectionne = Dialog.getNumber();
	
	//INITIALISATION DE LA BANDE --- A VERIFIER
	for (i=0; i<roiManager("count");i++){
        roiManager("Select", i);
        run("Make Band...", "band=" + bandeSelectionne);
        //roiManager("Update"); //In case you want to have the band selection replacing the original selection, otherwise delete the line
	}

	return bandeSelectionne;
}
function definirThreshold(){
	setBatchMode(false);
	selectImage(myImageID);
	setSlice(bandeSelectionne);
	run("Threshold..."); //Ouvre Threshold                          
	waitForUser("OK, pour appliquer le masque");
	
	run("Convert to Mask");                   

}

//FIN FONCTIONS CREE

//FONCTIONS DE BASE
function stack_imgs(files,name){
	if(files.length>1){
		command2 = "  title="+name;
		for(i=0;i<files.length;i++){
			index = i+1;
			command2=command2+" image"+index+"="+files[i];
		}
		run("Concatenate...", command2);
	}else{
		selectWindow(files[0]);
		rename(name);
	}
}
//for tests
function print_array(arr){
	for(i=0;i<arr.length;i++){
		print(arr[i]);
	}
}
function ask_for_selection(title,request){
	setTool(0);
	waitForUser(title,request);
	selectImage(myImageID);
	//Check if he no idiot
	if (selectionType() != 0){
		beep();
		if(getBoolean("Your rectangle is not a rectangle ! Do you want to continue ?"))
		{
			ask_for_selection(title,request);
		}else{
			exit();
		}
	}
}
function measureStack(){
	saveSettings;
	setOption("Stack position", true);
	for (n=1; n<=nSlices; n++) {
		setSlice(n);
		run("Measure");
	}
	restoreSettings;
}
function StDev(pole) {
    SUM=0;
    n=pole.length;
    mean=Mean(pole);
    for (x=0; x<n; x++) {
         SUM = SUM+square(pole[x]-mean);
    }
    return sqrt(SUM/(n-1));
}
function Mean(pole) {
    mean=0;
    n=pole.length;
    for (x=0; x<n; x++) {
        mean+=pole[x];
    }
    return mean/n;
}
function square(a) {
    return a*a;
}
//FIN FONCTION DE BASE