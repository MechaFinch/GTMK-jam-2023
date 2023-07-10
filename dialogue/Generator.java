import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

public class Generator {

    /*
     * From a plaintext writer-friendly script, generates
     * the actual instructions the game calls to display the text.
     * 
     * Spaces are used to distinguish between sets of player choices. 
     * Lines not starting with the given characters are ignored.
     * 
     * Script example:
     * 
     * A: Dialogue spoken by the AI. 
     * 
     * P: Player choice 1
     * P: Player choice 2
     * P: Player choice 3
     * 
     * P: Dialogue spoken by the player.
     * 
     * S: [raw code copied exactly, ex. calling a function that changes the music]
     */

    static final String readLinesStartingWith = "PAFG S";

    static final String colorAI = "COLOR_ROBOT_TEXT";
    static final String colorHuman = "COLOR_HUMAN_TEXT";
    static final String colorWhite = "COLOR_WHITE";
    static final String [] choiceColors = {"COLOR_CHOICE1", "COLOR_CHOICE2", "COLOR_CHOICE3"};
    static final String color2 = "COLOR_TRANSPARENT";

    static final int lineHeight = 1;
    static final int defaultVerticalPos = 21;
    static final int defaultHorizontalPos = 1;
    static final int charsPerLine = 38;

    static final String waitInput = "\ncall _dialog.wait_dialog with none;";
    static final String clearCode = "\ncall _dialog.reset_box with none;";

    static final String inputFileName = "intput.txt";
    static final String outputFileName = "output.txt";
    
    public static void main(String [] args) throws IOException {

        String [] lines = readLines(inputFileName);

        int [] lineBreakCounts = new int[lines.length];

        for(int i = 0; i < lines.length; i++) {
            lines[i] = formatDialogString(lines[i]);
			lineBreakCounts[i] = countLines(lines[i]);
        }

        ArrayList<String> outputStrings = new ArrayList<String>();

        //generate output strings for each segment 
        for(int i = 0; i < lines.length; i++) {

            if(lines[i].length() < 1) {
                continue;
            }

            char letter = lines[i].charAt(0);

            //AI dialogue, no need to check for choices
            if(letter == 'A') {

                outputStrings.add(clearCode);
                outputStrings.add(generateCode(lines[i].substring(3), colorAI, lineBreakCounts[i], i));
                outputStrings.add(waitInput);

            }

            //player dialogue, accounts for multiple choices
            if(letter == 'P') {

                outputStrings.add(clearCode);

                int [] choicesLines = {0, 0, 0};
                choicesLines[0] = lineBreakCounts[i];

                //look ahead for more choices 
                int choicesCount = 1;
                while(lines[i + choicesCount].length() > 0 && lines[i + choicesCount].charAt(0) == 'P' && choicesCount < 3) {
                    choicesLines[choicesCount] = lineBreakCounts[i + choicesCount];
                    choicesCount++;
                }

                String code = "";
                
                int choiceVerticalPos = defaultVerticalPos;
                for(int l = 0; l < choicesCount; l++) {
                    code += generateCode(lines[i + l].substring(3), choiceColors[l], lineBreakCounts[i + l], i + l, choiceVerticalPos);
                    int newlines = Math.max(1, lineBreakCounts[i + l]);
                    choiceVerticalPos += (newlines * lineHeight) + 1;
                }

                code = code + "\ncall _dialog.wait_choice with " + choicesCount + ", " + choicesLines[0] + ", " + choicesLines[1] + ", " + choicesLines[2] + ";";

                outputStrings.add(code);

                i += choicesCount - 1;
            }

            //factory dialogue
            if(letter == 'F') {

                outputStrings.add(clearCode);
                outputStrings.add(generateCode(lines[i].substring(3), colorWhite, lineBreakCounts[i], i));
                outputStrings.add(waitInput);

            }

            //game dialogue- could merge w factory dialogue its prob just a diff color 
            if(letter == 'G') {

                outputStrings.add(clearCode);
                outputStrings.add(generateCode(lines[i].substring(3), colorWhite, lineBreakCounts[i], i));
                outputStrings.add(waitInput);

            }

            //special flag for raw code 
            if(letter == 'S') {

                outputStrings.add("\n" + lines[i].substring(3));
            }
        }

        //clear what was in output.txt 
        PrintWriter writer = new PrintWriter(outputFileName);
        writer.print("");
        writer.close();

        //print to output.txt 
        FileWriter writer2 = new FileWriter(outputFileName); 
        for(String str: outputStrings) {
            writer2.write(str + System.lineSeparator());
        }
        writer2.close();

    }

    //overload for specifying line pos for choices 
    public static String generateCode(String dialogue, String color, int numLines, int id, int verticalPos) {

        String varname = "str" + id;
        String str = "";
        str += "\nconstant " + varname + " is string gets \"" + dialogue + "\";";
        str += "\ncall _text.a_string with to " + varname + ", sizeof " + varname + ", " + color + ", COLOR_TRANSPARENT, " + verticalPos + ", " + defaultHorizontalPos + ";";
        return str;

    }
    //id is unique for variable name 
    public static String generateCode(String dialogue, String color, int numLines, int id) {
        return generateCode(dialogue, color, numLines, id, defaultVerticalPos);
    }

    //count how many lines this would take
    public static int countLines(String str) {
		int n = 0;
		
		for(int i = 0; i < str.length() - 1; i++)
			if(str.charAt(i) == '\\' && str.charAt(i + 1) == 'n') n++;
		
		return n;
    }

    //insert line breaks, \ out quotes
    public static String formatDialogString(String str) {

        if(str.length() > 0 && str.charAt(0) == 'S') {
            return str;
        }
		
		int strIndex = 0;
		int lineIndex = 0;
		
		while(strIndex < str.length()) {
		    if(lineIndex >= charsPerLine) {
		        str = str.substring(0, str.lastIndexOf(' ', strIndex)) + "\\n" + str.substring(str.lastIndexOf(' ', strIndex) + 1);
		        
		        lineIndex = 5;
		    }
		    
			lineIndex++;
			strIndex++;
		}

        str.replaceAll("\"", "\\\"");
        str.replaceAll("\'", "\\\'");

        return str;

    }

    //from stackoverflow with modifications
    //read in only the relevant lines in the file 
    public static String[] readLines(String filename) throws IOException {
        FileReader fileReader = new FileReader(filename);
        BufferedReader bufferedReader = new BufferedReader(fileReader);

        List<String> lines = new ArrayList<String>();
        String line = null;
        while ((line = bufferedReader.readLine()) != null) {

            if(line.length() == 0) {
                lines.add(line);
            } else if(readLinesStartingWith.contains(line.substring(0, 1))) {
                lines.add(line);
            }
            
        }
        bufferedReader.close();
        return lines.toArray(new String[lines.size()]);
    }

}
