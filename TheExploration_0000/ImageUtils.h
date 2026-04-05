#pragma once

#include "CppCommponents/ImageRGBA.h";

namespace ImageUtils_
{
	void display_count_color_occurrences(const char* filepath);
	void map_color(ImageRGBA* image, const RGBA from, const RGBA to);

	bool equal(const RGBA& c1, const RGBA& c2);
}