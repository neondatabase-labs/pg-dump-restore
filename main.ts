import { type Options, execa } from "execa";
import { z } from "zod";

const argsSch = z.object({
	srcUrl: z.string().url(),
	destUrl: z.string().url(),
	callbackUrl: z.string().url(),
});

const handler = async (args: unknown) => {
	const { srcUrl, destUrl, callbackUrl } = argsSch.parse(args);
	let failed = false;
	let output = "";
	try {
		const result = await execa<Options>(
			"pg_dump",
			[
				"--no-owner",
				"--no-privileges",
				"--no-publications",
				"--no-subscriptions",
				"--no-tablespaces",
				"-Fc",
				"-d",
				srcUrl,
			],
			{
				timeout: 14 * 60 * 1000, // 14 minutes (AWS Lambda max is 15 minutes)
			},
		).pipe<Options>("pg_restore", ["-d", destUrl], {
			timeout: 14 * 60 * 1000, // 14 minutes (AWS Lambda max is 15 minutes)
			all: true,
		});
		if (result.failed) failed = true;
		output += result.pipedFrom[0]?.stderr?.toString() || "";
		output += result.all?.toString() || "";
	} catch (e) {
		failed = true;
		output += "JS/TS error thrown:\n";
		output +=
			e instanceof Error ? e.stack || e.message : JSON.stringify(e, null, 2);
		output += "\n\nDump stderr and Restore stdout and stderr below:\n\n";
	}

	await fetch(callbackUrl, {
		method: "POST",
		body: JSON.stringify({ output, failed }),
		headers: { "Content-Type": "application/json" },
	});
};

export default handler;
