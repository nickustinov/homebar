export declare enum IconStyle {
    REGULAR = "regular",
    THIN = "thin",
    LIGHT = "light",
    BOLD = "bold",
    FILL = "fill",
    DUOTONE = "duotone"
}
export declare enum IconCategory {
    ARROWS = "arrows",
    BRAND = "brands",
    COMMERCE = "commerce",
    COMMUNICATION = "communications",
    DESIGN = "design",
    DEVELOPMENT = "technology & development",
    EDITOR = "editor",
    FINANCE = "finances",
    GAMES = "games",
    HEALTH = "health & wellness",
    MAP = "maps & travel",
    MEDIA = "media",
    NATURE = "nature",
    OBJECTS = "objects",
    OFFICE = "office",
    PEOPLE = "people",
    SYSTEM = "system",
    WEATHER = "weather"
}
export declare enum FigmaCategory {
    ARROWS = "arrows",
    BRAND = "brands",
    COMMERCE = "commerce",
    COMMUNICATION = "communication",
    DESIGN = "design",
    DEVELOPMENT = "technology & development",
    EDUCATION = "education",
    FINANCE = "math & finance",
    GAMES = "games",
    HEALTH = "health & wellness",
    MAP = "maps & travel",
    MEDIA = "media",
    OFFICE = "office & editing",
    PEOPLE = "people",
    SECURITY = "security & warnings",
    SYSTEM = "system & devices",
    TIME = "time",
    WEATHER = "weather & nature"
}
export interface IconEntry {
    name: string;
    pascal_name: string;
    alias?: {
        name: string;
        pascal_name: string;
    };
    categories: readonly IconCategory[];
    figma_category: FigmaCategory;
    tags: readonly string[];
    codepoint: number;
    published_in: number;
    updated_in: number;
}
