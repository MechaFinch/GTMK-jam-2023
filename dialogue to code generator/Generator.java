import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Generator {

    static final int charsPerLine = 35;
    static final String readLinesStartingWith = "PAFG S";
    //parallel with above
    static final String [] colors = {"COLOR_HUMAN_TEXT", "COLOR_ROBOT_TEXT", "COLOR_WHITE", "COLOR_WHITE"};
    static final String colorAI = "COLOR_ROBOT_TEXT";
    static final String colorHuman = "COLOR_HUMAN_TEXT";
    static final String colorWhite = "COLOR_WHITE";
    static final String [] choiceColors = {"COLOR_CHOICE1", "COLOR_CHOICE2", "COLOR_CHOICE3"};
    static final String color2 = "COLOR_TRANSPARENT";

    static final String clearCode = "\ncall _dialog.reset_box with none;";

    public static void main(String [] args) throws IOException {



        String [] lines = readLines("input.txt");

        int [] lineBreakCounts = new int[lines.length];

        for(int i = 0; i < lines.length; i++) {
            lineBreakCounts[i] = determineLines(lines[i]);
        }


        ArrayList<String> outputStrings = new ArrayList<String>();

        //generate output strings for each segment 
        for(int i = 0; i < lines.length; i++) {

            if(lines[i].length() < 1) {
                continue;
            }

            char letter = lines[i].charAt(0);

            if(letter == 'A') {

                //AI dialogue, no need to check for choices
                outputStrings.add(clearCode);
                outputStrings.add(generateCode(lines[i].substring(3), colorAI, lineBreakCounts[i], i));

            }

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
                
                for(int l = 0; l < choicesCount; l++) {
                    code += generateCode(lines[i + l].substring(3), choiceColors[l], lineBreakCounts[i + l], i + l);
                }

                code = code + "\ncall _dialog.wait_dialog with " + choicesCount + ", " + choicesLines[0] + ", " + choicesLines[1] + ", " + choicesLines[2] + ";";

                outputStrings.add(code);

                i += choicesCount - 1;
            }

            if(letter == 'F') {

                //factory dialogue
                outputStrings.add(clearCode);
                outputStrings.add(generateCode(lines[i].substring(3), colorWhite, lineBreakCounts[i], i));


            }

            if(letter == 'G') {

                //game dialogue- could merge w factory dialogue its prob just a diff color 
                outputStrings.add(clearCode);
                outputStrings.add(generateCode(lines[i].substring(3), colorWhite, lineBreakCounts[i], i));


            }

            if(letter == 'S') {

                //special flag for raw code 

                outputStrings.add("\n" + lines[i].substring(3));
            }
        }

        //print to output.txt 
        FileWriter writer = new FileWriter("output.txt"); 
        for(String str: outputStrings) {
            writer.write(str + System.lineSeparator());
        }
        writer.close();

    }

    //id is unique for variable name 
    public static String generateCode(String dialogue, String color, int numLines, int id) {

        String varname = "str" + id;
        String str = "";
        str += "\nconstant " + varname + " is string gets \"" + dialogue + "\";";
        str += "\ncall _text.a_string with to " + varname + ", sizeof " + varname + ", " + color + ", COLOR_TRANSPARENT, 22, 2;";
        return str;

    }



    //count how many lines this would take and insert line breaks 
    public static int determineLines(String str) {

        int counter = 0; 
        while(counter * charsPerLine < str.length()) {

            counter++;
            int pos = counter * charsPerLine;
            if(pos < str.length()) {
                str = str.substring(0, pos) + '\n' + str.substring(pos);
            }
        }

        return counter;
    }


    //from stackoverflow with modifications 
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