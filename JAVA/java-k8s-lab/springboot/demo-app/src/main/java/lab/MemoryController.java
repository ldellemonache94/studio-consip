package lab;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
public class MemoryController {

    private List<byte[]> memory = new ArrayList<>();

    @GetMapping("/eat")
    public String eat() {
        memory.add(new byte[5 * 1024 * 1024]);
        return "Allocated: " + memory.size() * 5 + " MB";
    }
}