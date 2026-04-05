#include "CppCommponents/ImageRGBA.h"
#include <map>
#include <set>

#include <iostream>

bool operator<(const RGBA& lhs, const RGBA& rhs)
{
	return std::tie(lhs.r, lhs.g, lhs.b, lhs.a) < std::tie(rhs.r, rhs.g, rhs.b, rhs.a);
}

namespace ImageUtils_
{

	bool is_equal(const RGBA& a, const RGBA& b)
	{
		if (a.r != b.r)
		{
			return false;
		}

		if (a.g != b.g)
		{
			return false;
		}

		if (a.b != b.b)
		{
			return false;
		}

		if (a.a != b.a)
		{
			return false;
		}

		return true;
	}

	std::set<RGBA> get_unique_colors(const ImageRGBA& image)
	{
		std::set<RGBA> unique_colors;

		int width = ImageRGBA_::get_width(image);
		int height = ImageRGBA_::get_height(image);

		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				RGBA color = ImageRGBA_::get_pixel(image, x, y);
				unique_colors.insert(color);
			}
		}

		return unique_colors;
	}


	std::map<RGBA, int> count_color_occurrences(const ImageRGBA& image)
	{
		std::map<RGBA, int> color_counts;

		int width = ImageRGBA_::get_width(image);
		int height = ImageRGBA_::get_height(image);

		for (int y = 0; y < height; y++) {
			for (int x = 0; x < width; x++) {
				RGBA color = ImageRGBA_::get_pixel(image, x, y);
				color_counts[color]++;
			}
		}

		return color_counts;
	}





	void display_count_color_occurrences(const char* filepath)
	{
		ImageRGBA* image = ImageRGBA_::load(filepath);

		std::map<RGBA, int> color_counts = count_color_occurrences(*image);

		std::cout << "Unique colors After : " << color_counts.size() << "\n";

		for (const auto& [color, count] : color_counts)
		{
			std::cout << "R: " << static_cast<int>(color.r)
				<< " G: " << static_cast<int>(color.g)
				<< " B: " << static_cast<int>(color.b)
				<< " A: " << static_cast<int>(color.a)
				<< " Count: " << count << "\n";
		}
	}

	/// Replaces all pixels equal to `from` with `to`
	void map_color(ImageRGBA* image, const RGBA from, const RGBA to)
	{
		// 1) grab dimensions
		int w = ImageRGBA_::get_width(*image);
		int h = ImageRGBA_::get_height(*image);

		// 2) loop over every pixel
		for (int y = 0; y < h; ++y) {
			for (int x = 0; x < w; ++x) {
				RGBA pix = ImageRGBA_::get_pixel(*image, x, y);
				// 3) compare via the supplied operator==
				if (pix == from) {
					// 4) swap in the new color
					ImageRGBA_::set_pixel(*image, x, y, to);
				}
			}
		}
	}

	bool equal(const RGBA& c1, const RGBA& c2)
	{
		return c1.r == c2.r
			&& c1.g == c2.g
			&& c1.b == c2.b
			&& c1.a == c2.a;
	}

}