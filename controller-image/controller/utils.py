
import os

def symlink_search(path):
    result = list()

    walk = next(os.walk(path))
    root = walk[0]
    dirs = walk[1]
    files = walk[2]

    link_candidates = dirs.copy()
    link_candidates.extend(files)
    for c in link_candidates:
        if os.path.islink(f"{root}/{c}"):
            link = f"{root}/{c}"
            target = f"{os.readlink(link)}"

            result.append(f"{target} {link}")

    for d in dirs:
        result.extend(symlink_search(f"{root}/{d}"))

    return result


def get_dir_size(path):
    size = 0
    for it in os.scandir(path):
        if it.is_file():
            size += os.path.getsize(it)
        elif it.is_dir():
            size += get_dir_size(it.path)
    return size
