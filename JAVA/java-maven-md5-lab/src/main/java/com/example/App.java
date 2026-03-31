package com.example;

/**
 * Classe principale dell'applicazione.
 * VERSIONE 1 - Calcolo del saluto base.
 */
public class App {

    /**
     * Genera un messaggio di saluto.
     *
     * @param name il nome da salutare
     * @return stringa di saluto
     */
    public String greet(String name) {
        return "Hello, " + name + "!";
    }

    public static void main(String[] args) {
        App app = new App();
        System.out.println(app.greet("World"));
    }
}
