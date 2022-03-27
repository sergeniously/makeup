#include <az-json/Writer.h>

int main(int argn, const char** argv)
{
    az::json::Writer(std::cout).pretty().write({
        {"comment", "This is a makeup demo cpp program that uses az-json external project!"},
        {"copyright", "Belenkov Sergey, 2022"},
        {"url", "https://github.com/sergeniously/makeup"}
    });
    std::cout << std::endl;
    return 0;
}
