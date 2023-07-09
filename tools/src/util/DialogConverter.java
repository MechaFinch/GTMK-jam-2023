package util;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public class DialogConverter {
    
    private static final String linePrefixes = "PAFGS",
                                infile = "../dialogue/input.txt",
                                outfile = "../dialogue/output.txt",
                                
                                colorAI = "COLOR_ROBOT_TEXT",
                                colorHuman = "COLOR_HUMAN_TEXT",
                                colorWhite = "COLOR_WHITE",
                                noColor = "COLOR_TRANSPARENT",
                                
                                clearCode = "call _dialog.reset_box with none;",
                                waitInput = "call _dialog.wait_dialog with none;";
    
    private static final String[] choiceColors = {
            "COLOR_CHOICE1",
            "COLOR_CHOICE2",
            "COLOR_CHOICE3"
    };
    
    private static final int lineHeight = 2,
                             defaultVPos = 21,
                             defaultHPos = 1,
                             maxLineWidth = 38;
    
    public static void main(String[] args) throws IOException {
        
        List<String> inputLines = Files.readAllLines(Paths.get(infile)),
                     outputLines = new ArrayList<>();
        
        // remove lines that don't start with a character in the prefix string
        // format lines
        inputLines.stream()
                  .filter(s -> linePrefixes.chars().anyMatch(x -> x == s.charAt(0)))
                  .map(DialogConverter::formatDialogString);
        
        // process lines
        for(String line : inputLines) {
            // count line breaks
            int lbCount = line.chars().reduce(0, (a, c) -> a + (c == '\n' ? 1 : 0));
            
            switch(line.charAt(0)) {
                case 'A':
                    // AI dialogue
                    outputLines.add(clearCode);
                    //generateCode(outputLines, line, colorAI)
                    outputLines.add(waitInput);
                    
                    break;
                
                case 'P':
                    // ???
                    break;
                
                case 'F':
                    // Factory dialogue
                    break;
                
                case 'G':
                    // Game dialogue
                    break;
                
                case 'S':
                    // Special - raw code
                    break;
                
                default:
                    System.out.println("Unknown prefix from line: " + line);
            }
        }
        
        try(PrintWriter writer = new PrintWriter(Paths.get(outfile).toFile())) {
            for(String line : outputLines) {
                writer.println(line);
            }
        }
    }
    
    /**
     * Formats the string by inserting line breaks and escaping quotes
     * 
     * @param s
     * @return
     */
    private static String formatDialogString(String str) {
        if(str.startsWith("S")) return str;
        
        // newline insertion
        StringBuilder sb = new StringBuilder();
        int strIndex = 0,
            lineIndex = 0,  // index in current line 
            lastSpace = -1; // index in 
        /*
        for(int strIndex = 0, lineIndex = 0; strIndex < str.length(); strIndex++) {
            char c = str.charAt(strIndex);
            
        }*/
        
        
        
        // quote escaping
        String s = sb.toString();
        
        s.replaceAll("\"", "\\\"");
        s.replaceAll("\'", "\\\'");
        
        return s;
    }
}
